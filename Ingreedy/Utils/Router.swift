import SwiftUI
import FirebaseAuth

/// Uygulama içi rotalar
enum Route {
    case login
    case register
    case home
    case recipes
    case ingredientSuggestion
    case profile
    
    /// Rotaların metin karşılıkları
    func description() -> String {
        switch self {
        case .login: return "Login"
        case .register: return "Register" 
        case .home: return "Home"
        case .recipes: return "Recipes"
        case .ingredientSuggestion: return "Ingredient Suggestion"
        case .profile: return "Profile"
        }
    }
}

/// Uygulama navigasyon kontrolcüsü
class Router: ObservableObject {
    // MARK: - Properties
    @Published var currentRoute: Route = .login
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        removeAuthStateListener()
    }
    
    // MARK: - Public Methods
    
    /// Belirtilen rotaya navigasyon gerçekleştirir
    /// - Parameter route: Hedef rota
    func navigate(to route: Route) {
        print("Navigating from \(currentRoute.description()) to \(route.description())")
        self.currentRoute = route
    }
    
    /// Kullanıcının oturum durumunu kontrol eder ve uygun sayfaya yönlendirir
    func checkAuthAndNavigate() {
        if FirebaseAuthenticationService.shared.currentUser != nil {
            print("User is logged in, navigating to Home")
            self.currentRoute = .home
        } else {
            print("User is not logged in, navigating to Login")
            self.currentRoute = .login
        }
    }
    
    // MARK: - Private Methods
    
    /// Firebase oturum değişikliği dinleyicisini ayarlar
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if user != nil {
                    if self.currentRoute == .login || self.currentRoute == .register {
                        self.navigate(to: .home)
                    }
                } else {
                    self.navigate(to: .login)
                }
            }
        }
    }
    
    /// Firebase oturum değişikliği dinleyicisini kaldırır
    private func removeAuthStateListener() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
} 