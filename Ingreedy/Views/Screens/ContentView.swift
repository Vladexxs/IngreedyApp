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
        HStack {
            Spacer()
            // Ana Sayfa butonu
            Button(action: {
                router.navigate(to: .home)
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundColor(router.currentRoute == .home ? AppColors.accent : AppColors.primary)
                    Text("Home")
                        .font(.caption)
                        .foregroundColor(router.currentRoute == .home ? AppColors.accent : AppColors.primary)
                }
            }
            Spacer()
            // Arama butonu
            Button(action: {
                router.navigate(to: .recipes)
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(router.currentRoute == .recipes ? AppColors.accent : AppColors.primary)
                    Text("Search")
                        .font(.caption)
                        .foregroundColor(router.currentRoute == .recipes ? AppColors.accent : AppColors.primary)
                }
            }
            Spacer()
            // Malzeme önerisi butonu
            Button(action: {
                router.navigate(to: .ingredientSuggestion)
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 64, height: 64)
                    Image(systemName: "chef.hat")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .offset(y: -15)
            }
            Spacer()
            // Paylaşılanlar butonu (eski Alerts yerine)
            Button(action: {
                router.navigate(to: .sharedRecipes)
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundColor(router.currentRoute == .sharedRecipes ? AppColors.accent : AppColors.primary)
                    Text("Paylaşılanlar")
                        .font(.caption)
                        .foregroundColor(router.currentRoute == .sharedRecipes ? AppColors.accent : AppColors.primary)
                }
            }
            Spacer()
            // Profil butonu
            Button(action: {
                router.navigate(to: .profile)
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "person")
                        .font(.title2)
                        .foregroundColor(router.currentRoute == .profile ? AppColors.accent : AppColors.primary)
                    Text("Profile")
                        .font(.caption)
                        .foregroundColor(router.currentRoute == .profile ? AppColors.accent : AppColors.primary)
                }
            }
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(Router())
} 

