import SwiftUI
import FirebaseCore

/// Ana içerik görünümü
struct ContentView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arka plan
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                // İçerik alanı
                VStack(spacing: 0) {
                    // Ana içerik alanı - tüm sayfaları içerir
                    ZStack {
                        switch router.currentRoute {
                        case .login:
                            LoginView()
                        case .register:
                            RegisterView()
                        case .home:
                            HomeView()
                        case .recipes:
                            RecipeListView()
                        case .ingredientSuggestion:
                            IngredientSuggestionView()
                        case .profile:
                            ProfileView()
                        case .sharedRecipes:
                            SharedRecipesView()
                        }
                    }
                    .frame(width: geometry.size.width)
                    
                    // Tab bar'ı sadece oturum açıldığında göster
                    if router.currentRoute != .login && router.currentRoute != .register {
                        CustomTabBar()
                            .frame(height: 90)
                            .background(
                                AppColors.tabBar
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                                    .edgesIgnoringSafeArea(.bottom)
                            )
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom) // Alt güvenli alanı yoksay
    }
}

/// Özelleştirilmiş tab bar
struct CustomTabBar: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    
    // MARK: - Body
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                tabBarButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: router.currentRoute == .home,
                    action: { router.navigate(to: .home) }
                )
                .frame(maxWidth: .infinity)
                tabBarButton(
                    icon: "magnifyingglass",
                    title: "Search",
                    isSelected: router.currentRoute == .recipes,
                    action: { router.navigate(to: .recipes) }
                )
                .frame(maxWidth: .infinity)
                Color.clear.frame(width: 64) // Ortadaki yuvarlak için boşluk
                tabBarButton(
                    icon: "person.2.fill",
                    title: "Shared",
                    isSelected: router.currentRoute == .sharedRecipes,
                    action: { router.navigate(to: .sharedRecipes) }
                )
                .frame(maxWidth: .infinity)
                tabBarButton(
                    icon: "person",
                    title: "Profile",
                    isSelected: router.currentRoute == .profile,
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
    private func tabBarButton(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.primary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.primary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(Router())
} 

