import Foundation
import Combine
import FirebaseFirestore

/// ProfileViewModel, kullanıcı profil bilgilerini ve çıkış işlemlerini yöneten ViewModel sınıfı
@MainActor
class ProfileViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoggedOut: Bool = false
    @Published var favoriteRecipes: [Recipe] = []
    
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
} 