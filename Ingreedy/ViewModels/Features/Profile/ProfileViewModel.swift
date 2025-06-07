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
        print("[ProfileViewModel] fetchCurrentUser çağrıldı")
        // Cache'i temizle ve fresh data al
        if let currentUser = authService.currentUser {
            print("[ProfileViewModel] AuthService'den kullanıcı alındı: \(currentUser.id)")
            // Önce local user'ı güncelle
            user = currentUser
            // Sonra Firestore'dan fresh data çek
            fetchUser(withId: currentUser.id)
        } else {
            print("[ProfileViewModel] AuthService'den kullanıcı alınamadı")
            user = nil
        }
    }
    
    /// Kullanıcıyı sistemden çıkışını gerçekleştirir
    func logout() {
        performNetwork({ completion in
            do {
                try self.authService.logout()
                
                // Cache temizleme işlemini güvenli hale getir
                DispatchQueue.global(qos: .background).async {
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
            print("[ProfileViewModel] Logout completed and profile caches cleared")
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
        print("[ProfileViewModel] fetchUser başlatıldı, ID: \(id)")
        let db = Firestore.firestore()
        db.collection("users").document(id).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else { 
                print("[ProfileViewModel] Firestore verisi alınamadı: \(error?.localizedDescription ?? "Unknown error")")
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
            
            print("[ProfileViewModel] Firestore'dan alınan FRESH veriler:")
            print("  - Email: \(email)")
            print("  - FullName: \(fullName)")
            print("  - Username: \(username ?? "nil")")
            print("  - ProfileImageUrl: \(profileImageUrl ?? "nil")")
            print("  - HasCompletedSetup: \(hasCompletedSetup)")
            
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
                print("[ProfileViewModel] FRESH User modeli güncellendi")
                self.user = userWithId
                
                // AuthService cache'ini de hemen güncelle
                self.authService.updateCurrentUser(userWithId)
                
                // Profil resmini yükle - hem Kingfisher hem de backup için
                if let imageUrl = profileImageUrl, !imageUrl.isEmpty {
                    print("[ProfileViewModel] Profil resmi indiriliyor...")
                    self.downloadAndSetProfileImage(fromPathForUserId: id)
                } else {
                    print("[ProfileViewModel] Profil resmi URL'si boş veya nil")
                }
            }
        }
    }

    // Firestore'a kullanıcı kaydet/güncelle
    func saveUser(_ user: User, completion: ((Error?) -> Void)? = nil) {
        print("[ProfileViewModel] saveUser çağrıldı: \(user.fullName), username: \(user.username ?? "nil")")
        let db = Firestore.firestore()
        do {
            var userData = try user.asDictionary()
            userData.removeValue(forKey: "id")
            userData["updatedAt"] = FieldValue.serverTimestamp() // Güncelleme zamanını ekle
            
            db.collection("users").document(user.id).setData(userData, merge: true) { [weak self] error in
                if let error = error {
                    print("[ProfileViewModel] Firestore save error: \(error.localizedDescription)")
                    completion?(error)
                } else {
                    print("[ProfileViewModel] Firestore save successful - FRESH DATA SAVED")
                    // Update local user immediately with fresh data
                    DispatchQueue.main.async {
                        self?.user = user
                        // Update AuthService cache immediately with fresh data
                        self?.authService.updateCurrentUser(user)
                        print("[ProfileViewModel] Local user and AuthService cache updated with FRESH data")
                        
                        // Veri güncellendikten sonra fresh data'yı tekrar çek
                        self?.fetchUser(withId: user.id)
                    }
                    completion?(nil)
                }
            }
        } catch {
            print("[ProfileViewModel] User serialization error: \(error.localizedDescription)")
            completion?(error)
        }
    }

    // Sadece profil fotoğrafı URL'sini güncelle
    func updateProfileImageUrl(_ url: String) {
        guard let user = user else { return }
        let db = Firestore.firestore()
        print("Updating DB with URL: \(url)")
        
        // Cache temizleme işlemini güvenli hale getir
        DispatchQueue.global(qos: .background).async {
            if let currentImageUrl = user.profileImageUrl {
                CacheManager.shared.clearProfileImageCache(forURL: currentImageUrl)
            }
            CacheManager.shared.clearProfileImageCache(forURL: url)
            CacheManager.shared.clearProfileImageCache(forUserId: user.id)
        }
        
        db.collection("users").document(user.id).updateData([
            "profileImageUrl": url,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Profil fotoğrafı URL güncelleme hatası: \(error)")
                return
            }
            DispatchQueue.main.async {
                print("Firestore güncellendi: \(url)")
                if let user = self.user {
                    let updatedUser = User(
                        id: user.id,
                        email: user.email,
                        fullName: user.fullName,
                        username: user.username,
                        favorites: user.favorites,
                        friends: user.friends,
                        profileImageUrl: url,
                        createdAt: user.createdAt,
                        hasCompletedSetup: user.hasCompletedSetup
                    )
                    self.user = updatedUser
                    // AuthService cache'ini hemen güncelle
                    self.authService.updateCurrentUser(updatedUser)
                }
                // Bir miktar bekledikten sonra fresh data çek
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.downloadAndSetProfileImage(fromPathForUserId: self.user!.id)
                }
                print("Local user profileImageUrl: \(self.user?.profileImageUrl ?? "nil")")
            }
        }
    }

    // Profil fotoğrafı yükle ve URL'yi güncelle, sonra resmi indir
    func uploadProfileImage(_ image: UIImage) {
        guard let user = user else { return }
        isUploading = true
        self.downloadedProfileImage = image // Yükleme sırasında geçici olarak seçilen resmi göster
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let imagePath = "profile_images/\(user.id).jpg"
        let ref = Storage.storage().reference().child(imagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(imageData, metadata: metadata) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                print("Upload error: \(error)")
                self.isUploading = false
                // Hata durumunda eski indirilen resmi (varsa) veya placeholder'ı göstermek için nil yap
                // self.downloadAndSetProfileImage(fromPathForUserId: user.id) // Tekrar eskiyi çekmeyi dene ya da
                // self.downloadedProfileImage = nil // eğer placeholder istiyorsak
                return
            }
            ref.downloadURL { url, error in
                self.isUploading = false
                if let error = error {
                    print("Download URL error: \(error)")
                    return
                }
                guard let downloadUrl = url else { 
                    print("URL is nil after upload")
                    return 
                }
                print("Obtained download URL: \(downloadUrl.absoluteString)")
                self.updateProfileImageUrl(downloadUrl.absoluteString) // Bu, downloadAndSetProfileImage'i tetikleyecek
            }
        }
    }

    // Profil fotoğrafını Storage path'inden indir ve ata
    func downloadAndSetProfileImage(fromPathForUserId userId: String) {
        let imagePath = "profile_images/\(userId).jpg"
        let storageRef = Storage.storage().reference().child(imagePath)

        print("[DownloadSDK] Storage referansı ile indirme deneniyor: \(imagePath)")
        
        storageRef.getData(maxSize: 10 * 1024 * 1024) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    let storageError = StorageErrorCode(rawValue: (error as NSError).code) ?? .unknown
                    print("[DownloadSDK] İndirme hatası (SDK): \(error.localizedDescription) - Hata Kodu: \(storageError)")
                    self.downloadedProfileImage = nil // Hata durumunda resmi temizle
                    return
                }
                guard let data = data, let image = UIImage(data: data) else {
                    print("[DownloadSDK] Veri alınamadı veya UIImage oluşturulamadı (SDK).")
                    self.downloadedProfileImage = nil // Hata durumunda resmi temizle
                    return
                }
                print("[DownloadSDK] İndirme BAŞARILI! UIImage oluşturuldu ve atandı (SDK).")
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