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
    @Published var currentRoute: Route = .loading // AUTH FIX: Loading ile başla, flicker önlensin
    @Published var hasNewSharedRecipeNotification: Bool = false
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var hasPerformedInitialCheck = false // AUTH FIX: Initial check tracker
    
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
        self.currentRoute = route
    }
    
    /// Animasyonsuz navigasyon gerçekleştirir
    /// - Parameter route: Hedef rota
    func navigateWithoutAnimation(to route: Route) {
        self.currentRoute = route
    }
    
    /// Loading ekranı tamamlandığında çağrılır
    func onLoadingComplete() {
        Task { @MainActor in
            // Get fresh user data from Firestore (not cached)
            guard let firebaseUser = Auth.auth().currentUser else {
                navigate(to: .login)
                return
            }
            
            do {
                // Force refresh user data by checking Firestore directly
                let userNeedsSetup = try await FirebaseAuthenticationService.shared.ensureFirestoreUserDocument(for: firebaseUser)
                
                if userNeedsSetup {
                    navigate(to: .setupUsername)
                } else {
                    navigate(to: .home)
                }
            } catch {
                // If there's an error, check cached user as fallback
                if let user = FirebaseAuthenticationService.shared.currentUser {
                    let needsUsernameSetup = !user.hasCompletedSetup || (user.username?.isEmpty ?? true)
                    
                    if needsUsernameSetup {
                        navigate(to: .setupUsername)
                    } else {
                        navigate(to: .home)
                    }
                } else {
                    navigate(to: .login)
                }
            }
        }
    }
    
    /// Kullanıcının oturum durumunu kontrol eder ve uygun sayfaya yönlendirir
    func checkAuthAndNavigate() {
        // AUTH FIX: Initial check'i sadece bir kez yap
        guard !hasPerformedInitialCheck else { return }
        hasPerformedInitialCheck = true
        
        // AUTH FIX: Hemen senkron kontrol
        if Auth.auth().currentUser != nil {
            // Kullanıcı var, loading'e git ve detaylı kontrolü orada yap
            self.currentRoute = .loading
        } else {
            // Kullanıcı yok, direkt login'e git
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Küçük delay ile flicker önle
                self.currentRoute = .login
            }
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
                // AUTH FIX: Sadece actual auth state değişikliklerinde tepki ver
                if user != nil {
                    // User logged in
                    if self.currentRoute == .login || self.currentRoute == .register {
                        self.navigateWithoutAnimation(to: .loading)
                    }
                } else {
                    // User logged out - sadece home/authenticated route'lardaysa login'e git
                    if ![.login, .register, .loading].contains(self.currentRoute) {
                        self.navigateWithoutAnimation(to: .login)
                    }
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