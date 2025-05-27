import Foundation
import Combine
import FirebaseFirestore

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
    @Published var userFavorites: [Int] = []
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
        performNetwork({ completion in
            self.recipeService.fetchRecipes(completion: completion)
        }, onSuccess: { [weak self] recipes in
            self?.featuredRecipes = Array(recipes.shuffled().prefix(2))
        })
    }
    
    func fetchPopularRecipes() {
        performNetwork({ completion in
            self.recipeService.fetchPopularRecipes(limit: 10, completion: completion)
        }, onSuccess: { [weak self] recipes in
            self?.popularRecipes = recipes
        })
    }
    
    func fetchFeaturedRecipesByMealType() {
        performNetwork({ completion in
            self.recipeService.fetchRecipesByMealType(self.selectedMealType, completion: completion)
        }, onSuccess: { [weak self] recipes in
            self?.featuredRecipes = Array(recipes.shuffled().prefix(2))
        })
    }
    
    func fetchPopularRecipesByMealType() {
        performNetwork({ completion in
            self.recipeService.fetchRecipesByMealType(self.selectedMealType, completion: completion)
        }, onSuccess: { [weak self] recipes in
            let sorted = recipes.sorted { (a: Recipe, b: Recipe) in
                (a.rating ?? 0) > (b.rating ?? 0)
            }
            self?.popularRecipes = Array(sorted.prefix(10))
        })
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
    
    /// Kullanıcının favori tariflerini Firestore'dan çeker
    func fetchUserFavorites() {
        guard let userId = homeModel?.user.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(), let favorites = data["favorites"] as? [Int] else {
                DispatchQueue.main.async {
                    self.userFavorites = []
                }
                return
            }
            DispatchQueue.main.async {
                self.userFavorites = favorites
            }
        }
    }

    /// Favori tarif ekler
    func addRecipeToFavorites(recipeId: Int, completion: ((Error?) -> Void)? = nil) {
        guard let userId = homeModel?.user.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "favorites": FieldValue.arrayUnion([recipeId])
        ]) { error in
            self.fetchUserFavorites()
            completion?(error)
        }
    }

    /// Favori tariften çıkarır
    func removeRecipeFromFavorites(recipeId: Int, completion: ((Error?) -> Void)? = nil) {
        guard let userId = homeModel?.user.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "favorites": FieldValue.arrayRemove([recipeId])
        ]) { error in
            self.fetchUserFavorites()
            completion?(error)
        }
    }

    /// Firestore'dan güncel kullanıcıyı çekip homeModel.user'ı günceller
    func reloadCurrentUser(completion: (() -> Void)? = nil) {
        guard let userId = homeModel?.user.id else { completion?(); return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { completion?(); return }
            let email = data["email"] as? String ?? ""
            let fullName = data["fullName"] as? String ?? ""
            let favorites = data["favorites"] as? [Int] ?? []
            let friends: [Friend] = [] // Arkadaşlar için ek alanlar gerekiyorsa eklenebilir
            let profileImageUrl = data["profileImageUrl"] as? String
            let createdAt: Date? = nil // Tarih alanı gerekiyorsa eklenebilir
            let updatedUser = User(
                id: userId,
                email: email,
                fullName: fullName,
                favorites: favorites,
                friends: friends,
                profileImageUrl: profileImageUrl,
                createdAt: createdAt
            )
            DispatchQueue.main.async {
                self.homeModel = HomeModel(user: updatedUser)
                completion?()
            }
        }
    }
} 