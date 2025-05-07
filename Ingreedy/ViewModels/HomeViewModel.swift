import Foundation
import Combine

class HomeViewModel: BaseViewModel {
    @Published var homeModel: HomeModel?
    @Published var featuredRecipes: [Recipe] = [] // Featured tarifler için
    private let authService: AuthenticationServiceProtocol
    private let recipeService = RecipeService()
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        setupUser()
        fetchFeaturedRecipes()
    }
    
    private func setupUser() {
        guard let user = authService.currentUser else {
            return
        }
        self.homeModel = HomeModel(user: user)
    }
    
    func fetchFeaturedRecipes() {
        recipeService.fetchRecipes { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recipes):
                    // Rastgele 2 tarif seç
                    self?.featuredRecipes = Array(recipes.shuffled().prefix(2))
                case .failure(let error):
                    print("Featured tarifler alınamadı: \(error.localizedDescription)")
                    self?.featuredRecipes = []
                }
            }
        }
    }
    
    func logout() {
        do {
            try authService.logout()
        } catch {
            handleError(error)
        }
    }
} 