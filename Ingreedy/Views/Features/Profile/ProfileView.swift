import SwiftUI
import Kingfisher

/// Kullanıcı profil ekranı
@MainActor
struct ProfileView: View {
    // MARK: - Properties
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var router: Router
    @State private var showEditProfile = false
    
    // MARK: - Initialization
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ProfileHeaderView(onSettingsTapped: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            router.navigate(to: .modernSettings)
                        }
                    })
                    if let user = viewModel.user {
                        ProfileInfoCard(viewModel: viewModel)
                            .onTapGesture { showEditProfile = true }
                    }
                    ProfileFavoritesGridCard(
                        favoriteRecipes: viewModel.favoriteRecipes,
                        onRemoveFavorite: { recipe in
                            viewModel.removeRecipeFromFavorites(recipeId: recipe.id)
                        }
                    )
                }
                // Yükleniyor ve hata göstergeleri...
                if viewModel.isLoading {
                    IngreedyLoadingView()
                }
                if let error = viewModel.error {
                    IngreedyErrorView(
                        error: error,
                        retryAction: nil,
                        dismissAction: { viewModel.error = nil }
                    )
                }
            }
            .onChange(of: viewModel.isLoggedOut) { isLoggedOut in
                if isLoggedOut { router.navigate(to: .login) }
            }
            .onChange(of: viewModel.user) { user in
                // Preload profile image when user data changes - with fresh data
                if let user = user,
                   let urlString = user.profileImageUrl,
                   !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    print("[ProfileView] Preloading profile image: \(urlString)")
                    
                    KingfisherManager.shared.retrieveImage(with: url) { result in
                        switch result {
                        case .success(let imageResult):
                            print("[ProfileView] Profile image preloaded successfully from: \(imageResult.cacheType)")
                        case .failure(let error):
                            print("[ProfileView] Profile image preload failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .onAppear {
                if let user = viewModel.user {
                    viewModel.fetchUser(withId: user.id)
                }
                viewModel.fetchFavoriteRecipes()
            }
            .sheet(isPresented: $showEditProfile, onDismiss: {
                if let user = viewModel.user {
                    viewModel.fetchUser(withId: user.id)
                }
            }) {
                EditProfileView(viewModel: viewModel, isPresented: $showEditProfile)
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Çıkış yapma butonu
    private var logoutButton: some View {
        Button(action: {
            viewModel.logout()
        }) {
            Text("Çıkış Yap")
                .font(.headline)
                .foregroundColor(AppColors.buttonText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.buttonBackground)
                .cornerRadius(16)
                .shadow(color: AppColors.accent.opacity(0.2), radius: 6, y: 2)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(Router())
} 