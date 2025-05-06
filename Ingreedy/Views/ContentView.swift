import SwiftUI
import FirebaseCore

struct ContentView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                // Content area
                VStack(spacing: 0) {
                    // Main Content Area with all pages
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
                        }
                    }
                    .frame(width: geometry.size.width)
                    
                    // Show tab bar only when logged in
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
        .edgesIgnoringSafeArea(.bottom) // Important: ignore bottom safe area
    }
}

// CustomTabBar definition
struct CustomTabBar: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        HStack {
            Spacer()
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
            VStack(spacing: 5) {
                Image(systemName: "bell")
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
                Text("Alerts")
                    .font(.caption)
                    .foregroundColor(AppColors.primary)
            }
            Spacer()
            VStack(spacing: 5) {
                Image(systemName: "person")
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
                Text("Profile")
                    .font(.caption)
                    .foregroundColor(AppColors.primary)
            }
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}

#Preview {
    ContentView()
        .environmentObject(Router())
} 

