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
    @Published var selectedImage: UIImage?
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

    // Firestore'dan kullanıcıyı çek
    func fetchUser(withId id: String) {
        let db = Firestore.firestore()
        db.collection("users").document(id).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(User.self, from: jsonData)
                let userWithId = User(
                    id: id,
                    email: user.email,
                    fullName: user.fullName,
                    favorites: user.favorites,
                    friends: user.friends,
                    profileImageUrl: user.profileImageUrl
                )
                DispatchQueue.main.async {
                    self.user = userWithId
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

    // Profil fotoğrafı yükle ve Firestore'a URL kaydet
    func uploadProfileImage(_ image: UIImage) {
        guard let user = user else { return }
        isUploading = true
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let ref = Storage.storage().reference().child("profile_images/\(user.id).jpg")
        ref.putData(imageData, metadata: nil) { [weak self] _, error in
            guard let self = self else { return }
            if let error = error {
                print("Upload error: \(error)")
                self.isUploading = false
                return
            }
            ref.downloadURL { url, error in
                self.isUploading = false
                guard let url = url else { return }
                var updatedUser = user
                updatedUser.profileImageUrl = url.absoluteString
                self.saveUser(updatedUser) { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            self.user = updatedUser
                        }
                    }
                }
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