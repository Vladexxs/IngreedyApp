import SwiftUI
import FirebaseAuth

/// Uygulama içi rotalar
enum Route {
    case login
    case register
    case setupUsername
    case loading
    case home
    case recipes
    case ingredientSuggestion
    case profile
    case editProfile
    case sharedRecipes
    
    // Settings Routes
    case modernSettings
    case accountSettings
    case privacySettings
    case notificationSettings
    case helpSupport
    case about
    case termsPrivacy
    case deleteAccount
    
    /// Rotaların metin karşılıkları
    func description() -> String {
        switch self {
        case .login: return "Login"
        case .register: return "Register"
        case .setupUsername: return "Setup Username"
        case .loading: return "Loading"
        case .home: return "Home"
        case .recipes: return "Recipes"
        case .ingredientSuggestion: return "Ingredient Suggestion"
        case .profile: return "Profile"
        case .editProfile: return "Edit Profile"
        case .sharedRecipes: return "Paylaşılanlar"
        case .modernSettings: return "Modern Settings"
        case .accountSettings: return "Account Settings"
        case .privacySettings: return "Privacy Settings"
        case .notificationSettings: return "Notification Settings"
        case .helpSupport: return "Help & Support"
        case .about: return "About"
        case .termsPrivacy: return "Terms & Privacy"
        case .deleteAccount: return "Delete Account"
        }
    }
}

/// Uygulama navigasyon kontrolcüsü
class Router: ObservableObject {
    // MARK: - Properties
    @Published var currentRoute: Route = .login
    @Published var hasNewSharedRecipeNotification: Bool = false
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
    
    /// Animasyonsuz navigasyon gerçekleştirir
    /// - Parameter route: Hedef rota
    func navigateWithoutAnimation(to route: Route) {
        print("Navigating (no animation) from \(currentRoute.description()) to \(route.description())")
        self.currentRoute = route
    }
    
    /// Loading ekranı tamamlandığında çağrılır
    func onLoadingComplete() {
        print("🔄 [Router] Loading completed, checking user setup status...")
        
        Task { @MainActor in
            // Get fresh user data from Firestore (not cached)
            guard let firebaseUser = Auth.auth().currentUser else {
                print("❌ [Router] No Firebase user found, navigating to login")
                navigate(to: .login)
                return
            }
            
            do {
                // Force refresh user data by checking Firestore directly
                let userNeedsSetup = try await FirebaseAuthenticationService.shared.ensureFirestoreUserDocument(for: firebaseUser)
                
                if userNeedsSetup {
                    print("🔧 [Router] User needs username setup, navigating to setupUsername")
                    navigate(to: .setupUsername)
                } else {
                    print("✅ [Router] User setup complete, navigating to Home")
                    navigate(to: .home)
                }
            } catch {
                print("❌ [Router] Error checking user setup: \(error.localizedDescription)")
                // If there's an error, check cached user as fallback
                if let user = FirebaseAuthenticationService.shared.currentUser {
                    let needsUsernameSetup = !user.hasCompletedSetup || (user.username?.isEmpty ?? true)
                    
                    if needsUsernameSetup {
                        print("🔧 [Router] Fallback: User needs username setup, navigating to setupUsername")
                        navigate(to: .setupUsername)
                    } else {
                        print("✅ [Router] Fallback: User setup complete, navigating to Home")
                        navigate(to: .home)
                    }
                } else {
                    print("❌ [Router] No user data available, navigating to login")
                    navigate(to: .login)
                }
            }
        }
    }
    
    /// Kullanıcının oturum durumunu kontrol eder ve uygun sayfaya yönlendirir
    func checkAuthAndNavigate() {
        if FirebaseAuthenticationService.shared.currentUser != nil {
            print("User is logged in, showing loading screen")
            self.currentRoute = .loading
        } else {
            print("User is not logged in, navigating to Login")
            self.currentRoute = .login
        }
    }
    
    /// Yeni paylaşılan tarif bildirimini ayarlar
    /// - Parameter hasNotification: Bildirim durumu
    func setNewSharedRecipeNotification(_ hasNotification: Bool) {
        hasNewSharedRecipeNotification = hasNotification
    }
    
    // MARK: - Private Methods
    
    /// Firebase oturum değişikliği dinleyicisini ayarlar
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if user != nil {
                    if self.currentRoute == .login || self.currentRoute == .register {
                        self.navigateWithoutAnimation(to: .loading)
                    }
                } else {
                    self.navigateWithoutAnimation(to: .login)
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