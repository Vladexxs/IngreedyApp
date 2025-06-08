import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import Kingfisher

/// ProfileViewModel, kullanıcı profil bilgilerini ve çıkış işlemlerini yöneten ViewModel sınıfı
@MainActor
class ProfileViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoggedOut: Bool = false
    @Published var favoriteRecipes: [Recipe] = []
    @Published var selectedImage: UIImage? // Kullanıcının galeriden seçtiği yeni resim
    @Published var downloadedProfileImage: UIImage? // Storage'dan indirilen mevcut profil resmi
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let authService: AuthenticationServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        fetchCurrentUser()
    }
    
    // MARK: - Public Methods
    
    /// Mevcut kullanıcı bilgilerini servis üzerinden alır
    func fetchCurrentUser() {
        // Cache'i temizle ve fresh data al
        if let currentUser = authService.currentUser {
            // Önce local user'ı güncelle
            user = currentUser
            // Sonra Firestore'dan fresh data çek
            fetchUser(withId: currentUser.id)
        } else {
            user = nil
        }
    }
    
    /// Kullanıcıyı sistemden çıkışını gerçekleştirir
    func logout() {
        performNetwork({ completion in
            do {
                try self.authService.logout()
                
                // Cache temizleme işlemini daha güvenli hale getir - CacheCallbackCoordinator hatası için
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    CacheManager.shared.clearAllCaches()
                }
                
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }, onSuccess: { [weak self] _ in
            self?.isLoggedOut = true
            self?.downloadedProfileImage = nil // Çıkış yapıldığında resmi temizle
            self?.user = nil
        })
    }
    
    /// Kullanıcı adının uygunluğunu kontrol eder
    func checkUsernameAvailability(_ username: String) async -> Bool {
        let db = Firestore.firestore()
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces).lowercased()
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("username", isEqualTo: trimmedUsername)
                .getDocuments()
            
            return snapshot.documents.isEmpty
        } catch {
            print("Username availability check error: \(error)")
            return false
        }
    }
    
    /// Kullanıcının favori tariflerini Firestore'dan ve API'den çeker
    func fetchFavoriteRecipes() {
        guard let user = self.user else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.id).getDocument { snapshot, error in
            let favoriteIds = (snapshot?.data()? ["favorites"] as? [Int]) ?? []
            RecipeService().fetchRecipes { result in
                switch result {
                case .success(let allRecipes):
                    let favoriteRecipes = allRecipes.filter { favoriteIds.contains($0.id) }
                    DispatchQueue.main.async {
                        self.favoriteRecipes = favoriteRecipes
                    }
                case .failure(let error):
                    print("API'den tarifler çekilemedi: \(error)")
                    DispatchQueue.main.async {
                        self.favoriteRecipes = []
                    }
                }
            }
        }
    }
    
    /// Favori tariflerden çıkarma
    func removeRecipeFromFavorites(recipeId: Int) {
        guard let user = self.user else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        userRef.updateData([
            "favorites": FieldValue.arrayRemove([recipeId])
        ]) { [weak self] error in
            if let error = error {
                print("Favoriden çıkarma hatası: \(error)")
            } else {
                // Local listeyi de güncelle
                DispatchQueue.main.async {
                    self?.favoriteRecipes.removeAll { $0.id == recipeId }
                }
            }
        }
    }

    // Firestore'dan kullanıcıyı çek ve profil fotoğrafını indirmeyi tetikle
    func fetchUser(withId id: String) {
        let db = Firestore.firestore()
        db.collection("users").document(id).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { 
                return 
            }
            // Her alanı tek tek kontrol et ve default değer ata
            let email = data["email"] as? String ?? ""
            let fullName = data["fullName"] as? String ?? ""
            let username = data["username"] as? String
            let hasCompletedSetup = data["hasCompletedSetup"] as? Bool ?? false
            let favorites = data["favorites"] as? [Int] ?? []
            // friends alanı array of string veya array of dict olabilir
            var friends: [Friend] = []
            if let friendsRaw = data["friends"] as? [[String: Any]] {
                friends = friendsRaw.compactMap { dict in
                    guard let fullName = dict["fullName"] as? String else { return nil }
                    let profileImageUrl = dict["profileImageUrl"] as? String
                    return Friend(fullName: fullName, profileImageUrl: profileImageUrl)
                }
            } else if let friendsString = data["friends"] as? [String] {
                friends = friendsString.map { Friend(fullName: $0, profileImageUrl: nil) }
            }
            let profileImageUrl = data["profileImageUrl"] as? String
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            
            let userWithId = User(
                id: id,
                email: email,
                fullName: fullName,
                username: username,
                favorites: favorites,
                friends: friends,
                profileImageUrl: profileImageUrl,
                createdAt: createdAt,
                hasCompletedSetup: hasCompletedSetup
            )
            DispatchQueue.main.async {
                self.user = userWithId
                
                // AuthService cache'ini de hemen güncelle
                self.authService.updateCurrentUser(userWithId)
                
                // Profil resmi URL'si varsa Kingfisher tarafından yüklenecek, ekstra yükleme gereksiz
                if let imageUrl = profileImageUrl, !imageUrl.isEmpty {
                    // Profil resmi URL'si mevcut
                } else {
                    self.downloadedProfileImage = nil
                }
            }
        }
    }

    // Firestore'a kullanıcı kaydet/güncelle
    func saveUser(_ user: User, completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        do {
            var userData = try user.asDictionary()
            userData.removeValue(forKey: "id")
            userData["updatedAt"] = FieldValue.serverTimestamp()
            
            db.collection("users").document(user.id).setData(userData, merge: true) { [weak self] error in
                if let error = error {
                    completion?(error)
                } else {
                    DispatchQueue.main.async {
                        self?.user = user
                        self?.authService.updateCurrentUser(user)
                        self?.fetchUser(withId: user.id)
                    }
                    completion?(nil)
                }
            }
        } catch {
            completion?(error)
        }
    }

    // Profil fotoğrafı URL'sini güncelle ve cache'i optimize et
    func updateProfileImageUrl(_ url: String) {
        guard let user = user else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(user.id).updateData([
            "profileImageUrl": url,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                return
            }
            
            DispatchQueue.main.async {
                if let currentUser = self.user {
                    let updatedUser = User(
                        id: currentUser.id,
                        email: currentUser.email,
                        fullName: currentUser.fullName,
                        username: currentUser.username,
                        favorites: currentUser.favorites,
                        friends: currentUser.friends,
                        profileImageUrl: url,
                        createdAt: currentUser.createdAt,
                        hasCompletedSetup: currentUser.hasCompletedSetup
                    )
                    self.user = updatedUser
                    self.authService.updateCurrentUser(updatedUser)
                    
                                          // Wait longer before clearing selectedImage to ensure smooth transition
                                              DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                         self.selectedImage = nil
                         self.uploadProgress = 0.0
                         
                         // Cache temizleme işlemini daha güvenli şekilde yap
                         CacheManager.shared.clearProfileImageCache(forURL: url)
                     }
                }
            }
        }
    }

    // Profil fotoğrafı yükle ve anında UI'ı güncelle
    func uploadProfileImage(_ image: UIImage) {
        guard let user = user else { return }
        isUploading = true
        uploadProgress = 0.0
        self.selectedImage = image
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { 
            isUploading = false
            return 
        }
        
        let imagePath = "profile_images/\(user.id).jpg"
        let ref = Storage.storage().reference().child(imagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = ref.putData(imageData, metadata: metadata) { [weak self] _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isUploading = false
                }
                return
            }
            
            ref.downloadURL { url, error in
                DispatchQueue.main.async {
                    self.isUploading = false
                    
                    if let error = error {
                            return
                    }
                    
                    guard let downloadUrl = url else { 
                        return 
                    }
                    
                    self.uploadProgress = 1.0
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.updateProfileImageUrl(downloadUrl.absoluteString)
                    }
                }
            }
        }
        
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let self = self,
                  let progress = snapshot.progress else { return }
            
            let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            
            DispatchQueue.main.async {
                self.uploadProgress = percentComplete
            }
        }
    }

    // Profil fotoğrafını Storage path'inden indir ve ata
    func downloadAndSetProfileImage(fromPathForUserId userId: String) {
        let imagePath = "profile_images/\(userId).jpg"
        let storageRef = Storage.storage().reference().child(imagePath)
        
        storageRef.getData(maxSize: 10 * 1024 * 1024) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.downloadedProfileImage = nil // Hata durumunda resmi temizle
                    return
                }
                guard let data = data, let image = UIImage(data: data) else {
                    self.downloadedProfileImage = nil // Hata durumunda resmi temizle
                    return
                }
                self.downloadedProfileImage = image
            }
        }
    }
}

// Codable struct'ı dictionary'ye çeviren yardımcı extension:
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        return json as? [String: Any] ?? [:]
    }
} 