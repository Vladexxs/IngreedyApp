import Foundation
import Combine

class HomeViewModel: BaseViewModel {
    @Published var homeModel: HomeModel?
    @Published var featuredRecipes: [Recipe] = [] // Featured tarifler için
    @Published var popularRecipes: [Recipe] = [] // Popüler tarifler için
    @Published var selectedMealType: String = "Breakfast" {
        didSet {
            fetchFeaturedRecipesByMealType()
            fetchPopularRecipesByMealType()
        }
    }
    private let authService: AuthenticationServiceProtocol
    private let recipeService = RecipeService()
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        setupUser()
        fetchFeaturedRecipesByMealType()
        fetchPopularRecipesByMealType()
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
    
    func fetchPopularRecipes() {
        recipeService.fetchPopularRecipes(limit: 10) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recipes):
                    self?.popularRecipes = recipes
                case .failure(let error):
                    print("Popüler tarifler alınamadı: \(error.localizedDescription)")
                    self?.popularRecipes = []
                }
            }
        }
    }
    
    func fetchFeaturedRecipesByMealType() {
        recipeService.fetchRecipesByMealType(selectedMealType) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recipes):
                    self?.featuredRecipes = Array(recipes.shuffled().prefix(2))
                case .failure(let error):
                    print("Featured tarifler alınamadı: \(error.localizedDescription)")
                    self?.featuredRecipes = []
                }
            }
        }
    }
    
    func fetchPopularRecipesByMealType() {
        recipeService.fetchRecipesByMealType(selectedMealType) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recipes):
                    // rating'e göre sırala, ilk 10'u al
                    let sorted = recipes.sorted { (a: Recipe, b: Recipe) in
                        (a.rating ?? 0) > (b.rating ?? 0)
                    }
                    self?.popularRecipes = Array(sorted.prefix(10))
                case .failure(let error):
                    print("Popüler tarifler alınamadı: \(error.localizedDescription)")
                    self?.popularRecipes = []
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
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<18:
            return "Good Afternoon"
        case 18..<23:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    var timeBasedIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "sun.max.fill" // Morning sun
        case 12..<18:
            return "sun.and.horizon.fill" // Afternoon sun with horizon
        case 18..<23:
            return "moon.stars.fill" // Evening moon with stars
        default:
            return "moon.fill" // Night moon
        }
    }
} 