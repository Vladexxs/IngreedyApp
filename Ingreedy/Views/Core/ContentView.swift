import SwiftUI
import FirebaseCore

/// Ana içerik görünümü
struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @StateObject private var notificationService = NotificationService.shared
    @State private var keyboardHeight: CGFloat = 0 // KEYBOARD FIX: Track keyboard height
    
    // MARK: - Body
    var body: some View {
        // AUTH FIX: Initial loading state'de arka plan göster
        ZStack {
            // Arka plan - her zaman göster
            AppColors.background.ignoresSafeArea(.all)
                
                // İçerik alanı
                VStack(spacing: 0) {
                    // Ana içerik alanı - tüm sayfaları içerir
                    ZStack {
                        switch router.currentRoute {
                        case .login:
                            LoginView()
                        case .register:
                            RegisterView()
                        case .setupUsername:
                            SetupUsernameView()
                        case .loading:
                            SplashLoadingView()
                        case .home:
                            HomeView()
                        case .recipes:
                            RecipeListView()
                        case .ingredientSuggestion:
                            IngredientSuggestionView()
                        case .profile:
                            ProfileView()
                        case .editProfile:
                            EditProfileViewWrapper()
                        case .sharedRecipes:
                            SharedRecipesView()
                        // Settings Pages
                        case .modernSettings:
                            ModernSettingsView()
                        case .accountSettings:
                            AccountSettingsView()
                        case .privacySettings:
                            PrivacySettingsView()
                        case .notificationSettings:
                            NotificationSettingsView()
                        case .helpSupport:
                            HelpSupportView()
                        case .about:
                            AboutView()
                        case .termsPrivacy:
                            TermsPrivacyView()
                        case .deleteAccount:
                            DeleteAccountView()
                        }
                    }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Tab bar'ı sadece oturum açıldığında göster (loading ekranında da gizle)
                    // Settings sayfalarında da tab bar'ı gizle
                    // KEYBOARD FIX: Klavye açıkken tabbar'ı gizle
                    if shouldShowTabBar && keyboardHeight == 0 {
                        CustomTabBar()
                            .frame(height: 90)
                            .background(
                                AppColors.tabBar
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity)) // SMOOTH TRANSITION
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            // Global notification service'i başlat
            notificationService.setRouter(router)
            
            // Cache maintenance işlemini başlat (optimize edilmiş)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                CacheManager.shared.performMaintenanceIfNeeded()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            // Memory warning'de sadece memory cache temizle
            CacheManager.shared.handleMemoryWarning()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            // KEYBOARD FIX: Klavye açıldığında tabbar'ı gizle
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardRectangle.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            // KEYBOARD FIX: Klavye kapandığında tabbar'ı göster
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// Tab bar'ın gösterilip gösterilmeyeceğini belirler
    private var shouldShowTabBar: Bool {
        let authRoutes: [Route] = [.login, .register, .setupUsername, .loading]
        let settingsRoutes: [Route] = [.modernSettings, .accountSettings, .privacySettings, .notificationSettings, .helpSupport, .about, .termsPrivacy, .deleteAccount, .editProfile]
        
        return !authRoutes.contains(router.currentRoute) && !settingsRoutes.contains(router.currentRoute)
    }
}

/// Özelleştirilmiş tab bar
struct CustomTabBar: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @ObservedObject private var notificationService = NotificationService.shared
    
    // MARK: - Body
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                tabBarButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: router.currentRoute == .home,
                    hasNotification: false,
                    action: { router.navigate(to: .home) }
                )
                .frame(maxWidth: .infinity)
                tabBarButton(
                    icon: "magnifyingglass",
                    title: "Search",
                    isSelected: router.currentRoute == .recipes,
                    hasNotification: false,
                    action: { router.navigate(to: .recipes) }
                )
                .frame(maxWidth: .infinity)
                Color.clear.frame(width: 64) // Ortadaki yuvarlak için boşluk
                tabBarButton(
                    icon: "person.2.fill",
                    title: "Shared",
                    isSelected: router.currentRoute == .sharedRecipes,
                    hasNotification: notificationService.hasNewSharedRecipe,
                    action: { 
                        router.navigate(to: .sharedRecipes)
                        // Shared sayfasına gidince bildirimi temizle
                        notificationService.clearNotification()
                    }
                )
                .frame(maxWidth: .infinity)
                tabBarButton(
                    icon: "person",
                    title: "Profile",
                    isSelected: router.currentRoute == .profile,
                    hasNotification: false,
                    action: { router.navigate(to: .profile) }
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)

            // Ortadaki turuncu buton
            Button(action: {
                router.navigate(to: .ingredientSuggestion)
            }) {
                ZStack {
                    Circle()
                        .fill(router.currentRoute == .ingredientSuggestion ? AppColors.accent : AppColors.primary)
                        .frame(width: 64, height: 64)
                    Image("chef-hat")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                }
            }
            .offset(y: -25)
        }
    }

    // Tab bar butonunu oluşturan yardımcı fonksiyon
    @ViewBuilder
    private func tabBarButton(icon: String, title: String, isSelected: Bool, hasNotification: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                VStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? AppColors.accent : AppColors.primary)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(isSelected ? AppColors.accent : AppColors.primary)
                }
                
                // Bildirim badge'i
                if hasNotification {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(AppColors.accent)
                                .frame(width: 12, height: 12)
                                .offset(x: -8, y: -2)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(Router())
} 

