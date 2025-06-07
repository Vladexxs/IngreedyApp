import Foundation
import Combine
import FirebaseFirestore

// MARK: - HomeViewModel
class HomeViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var featuredRecipes: [Recipe] = []
    @Published var popularRecipes: [Recipe] = []
    @Published var selectedMealType: String = "Breakfast" {
        didSet {
            fetchFeaturedRecipesByMealType()
            fetchPopularRecipesByMealType()
        }
    }
    @Published var userFavorites: [Int] = []
    
    // MARK: - Private Properties
    private let authService: AuthenticationServiceProtocol
    private let recipeService = RecipeService()
    
    // MARK: - Initializer
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        setupUser()
        fetchFeaturedRecipesByMealType()
        fetchPopularRecipesByMealType()
        fetchUserFavorites()
    }
    
    // MARK: - User Setup
    private func setupUser() {
        guard let user = authService.currentUser else {
            return
        }
        self.currentUser = user
    }
    
    // MARK: - Recipe Fetching Methods
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
    
    // MARK: - Authentication
    func logout() {
        do {
            try authService.logout()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - UI Helper Properties
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
            return "sun.max.fill"
        case 12..<18:
            return "sun.and.horizon.fill"
        case 18..<23:
            return "moon.stars.fill"
        default:
            return "moon.fill"
        }
    }
    
    var userName: String {
        return currentUser?.fullName ?? "User"
    }
    
    var userProfileImageUrl: String? {
        return currentUser?.profileImageUrl
    }
    
    // MARK: - Favorites Management
    /// Kullanıcının favori tariflerini Firestore'dan çeker
    func fetchUserFavorites() {
        guard let userId = currentUser?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(), 
                  let favorites = data["favorites"] as? [Int] else {
                DispatchQueue.main.async {
                    self?.userFavorites = []
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.userFavorites = favorites
            }
        }
    }

    /// Favori tarif ekler
    func addRecipeToFavorites(recipeId: Int, completion: ((Error?) -> Void)? = nil) {
        guard let userId = currentUser?.id else { 
            completion?(NSError(domain: "HomeViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
            return 
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "favorites": FieldValue.arrayUnion([recipeId])
        ]) { [weak self] error in
            if error == nil {
                self?.fetchUserFavorites()
            }
            completion?(error)
        }
    }

    /// Favori tariften çıkarır
    func removeRecipeFromFavorites(recipeId: Int, completion: ((Error?) -> Void)? = nil) {
        guard let userId = currentUser?.id else { 
            completion?(NSError(domain: "HomeViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
            return 
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "favorites": FieldValue.arrayRemove([recipeId])
        ]) { [weak self] error in
            if error == nil {
                self?.fetchUserFavorites()
            }
            completion?(error)
        }
    }
    
    /// Favori durumunu kontrol eder
    func isRecipeFavorite(_ recipeId: Int) -> Bool {
        return userFavorites.contains(recipeId)
    }
    
    /// Favori durumunu toggle eder
    func toggleFavorite(for recipeId: Int, completion: ((Error?) -> Void)? = nil) {
        if isRecipeFavorite(recipeId) {
            removeRecipeFromFavorites(recipeId: recipeId, completion: completion)
        } else {
            addRecipeToFavorites(recipeId: recipeId, completion: completion)
        }
    }

    /// Firestore'dan güncel kullanıcıyı çekip currentUser'ı günceller
    func reloadCurrentUser(completion: (() -> Void)? = nil) {
        guard let userId = currentUser?.id else { 
            completion?()
            return 
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data() else { 
                completion?()
                return 
            }
            
            let email = data["email"] as? String ?? ""
            let fullName = data["fullName"] as? String ?? ""
            let username = data["username"] as? String
            let favorites = data["favorites"] as? [Int] ?? []
            let friends: [Friend] = [] // Friends loading can be implemented later
            let profileImageUrl = data["profileImageUrl"] as? String
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            
            let updatedUser = User(
                id: userId,
                email: email,
                fullName: fullName,
                username: username,
                favorites: favorites,
                friends: friends,
                profileImageUrl: profileImageUrl,
                createdAt: createdAt
            )
            
            DispatchQueue.main.async {
                self?.currentUser = updatedUser
                self?.userFavorites = favorites
                completion?()
            }
        }
    }
} 