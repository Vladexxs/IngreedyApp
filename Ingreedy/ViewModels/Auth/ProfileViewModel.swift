import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

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
        // Mevcut kullanıcının fotoğrafını başlangıçta yükle
        if let userId = self.user?.id {
            fetchUser(withId: userId) // Bu, fetchUser içindeki testDownloadImage'i tetikleyecek
        }
    }
    
    // MARK: - Public Methods
    
    /// Mevcut kullanıcı bilgilerini servis üzerinden alır
    func fetchCurrentUser() {
        user = authService.currentUser
    }
    
    /// Kullanıcıyı sistemden çıkışını gerçekleştirir
    func logout() {
        performNetwork({ completion in
            do {
                try self.authService.logout()
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
            guard let self = self, let data = snapshot?.data() else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                struct FirestoreUser: Codable {
                    let email: String
                    let fullName: String
                    var favorites: [Int]
                    var friends: [String]
                    var profileImageUrl: String?
                }
                let firestoreUser = try JSONDecoder().decode(FirestoreUser.self, from: jsonData)
                let userWithId = User(
                    id: id,
                    email: firestoreUser.email,
                    fullName: firestoreUser.fullName,
                    favorites: firestoreUser.favorites,
                    friends: firestoreUser.friends,
                    profileImageUrl: firestoreUser.profileImageUrl
                )
                DispatchQueue.main.async {
                    self.user = userWithId
                    // Eğer profil URL'si varsa, resmi indirmeyi dene
                    if let imageUrl = firestoreUser.profileImageUrl, !imageUrl.isEmpty {
                        self.downloadAndSetProfileImage(fromPathForUserId: id) // Path ile indir
                    }
                }
            } catch {
                print("User decode error: \(error)")
            }
        }
    }

    // Firestore'a kullanıcı kaydet/güncelle
    func saveUser(_ user: User, completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        do {
            var userData = try user.asDictionary()
            userData.removeValue(forKey: "id")
            db.collection("users").document(user.id).setData(userData, merge: true) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }

    // Sadece profil fotoğrafı URL'sini güncelle
    func updateProfileImageUrl(_ url: String) {
        guard let user = user else { return }
        let db = Firestore.firestore()
        print("Updating DB with URL: \(url)")
        
        // URL Firestore'a kaydedildikten sonra yeni resmi indir ve ata
        // downloadAndSetProfileImage(fromPathForUserId: user.id) // Path ile indir

        db.collection("users").document(user.id).updateData([
            "profileImageUrl": url
        ]) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Profil fotoğrafı URL güncelleme hatası: \(error)")
                return
            }
            DispatchQueue.main.async {
                print("Firestore güncellendi: \(url)")
                self.user?.profileImageUrl = url
                // URL güncellendikten sonra path kullanarak indir.
                self.downloadAndSetProfileImage(fromPathForUserId: self.user!.id)
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