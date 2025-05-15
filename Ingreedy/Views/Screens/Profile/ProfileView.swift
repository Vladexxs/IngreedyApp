import SwiftUI

/// Kullanıcı profil ekranı
@MainActor
struct ProfileView: View {
    // MARK: - Properties
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var router: Router
    
    // MARK: - Initialization
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Arka plan
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppConstants.Spacing.large) {
                // Başlık
                Text("Profile")
                    .font(.system(size: AppConstants.FontSize.title, weight: .bold))
                    .foregroundColor(AppColors.primary)
                    .padding(.top, AppConstants.Spacing.extraLarge)
                
                // Kullanıcı bilgileri veya yükleniyor mesajı
                if let user = viewModel.user {
                    profileContent(user: user)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favori Tariflerim")
                            .font(.headline)
                            .padding(.top)
                        if viewModel.favoriteRecipes.isEmpty {
                            Text("Henüz favori tarifiniz yok.")
                                .font(.subheadline)
                                .foregroundColor(AppColors.text)
                                .padding(.vertical, 2)
                        } else {
                            ForEach(viewModel.favoriteRecipes, id: \ .id) { recipe in
                                Text(recipe.name)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.primary)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("User information not available")
                        .foregroundColor(AppColors.text)
                }
                
                Spacer()
                
                // Çıkış butonu
                logoutButton
            }
            .padding(.horizontal, AppConstants.Spacing.extraLarge)
            
            // Yükleniyor göstergesi
            if viewModel.isLoading {
                LoadingView()
            }
            
            // Hata göstergesi
            if let error = viewModel.error {
                ErrorView(
                    error: error,
                    retryAction: nil,
                    dismissAction: {
                        viewModel.error = nil
                    }
                )
            }
        }
        .onChange(of: viewModel.isLoggedOut) { isLoggedOut in
            if isLoggedOut {
                router.navigate(to: .login)
            }
        }
        .onAppear {
            viewModel.fetchFavoriteRecipes()
        }
    }
    
    // MARK: - Private Views
    
    /// Kullanıcı profil içeriğini oluşturur
    /// - Parameter user: Kullanıcı bilgileri
    private func profileContent(user: User) -> some View {
        VStack(alignment: .center, spacing: AppConstants.Spacing.medium) {
            // Kullanıcı avatarı
            Circle()
                .fill(AppColors.accent)
                .frame(width: 120, height: 120)
                .overlay(
                    Text(String(user.fullName.prefix(1).uppercased()))
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                )
                .padding(.bottom, AppConstants.Spacing.medium)
            
            // Kullanıcı adı
            Text(user.fullName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.primary)
            
            // Email adresi
            Text(user.email)
                .font(.system(size: 16))
                .foregroundColor(AppColors.text)
            
            Divider()
                .padding(.vertical, AppConstants.Spacing.medium)
            
            // İleriki sürümlerde eklenebilecek bölümler:
            // Favori tarifler, değerlendirme geçmişi vb.
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppConstants.CornerRadius.medium)
                .fill(AppColors.card)
        )
        .shadow(color: AppConstants.Shadow.small, radius: AppConstants.Shadow.radius, y: AppConstants.Shadow.y)
    }
    
    /// Çıkış yapma butonu
    private var logoutButton: some View {
        Button(action: {
            viewModel.logout()
        }) {
            Text("Logout")
                .font(.headline)
                .foregroundColor(AppColors.buttonText)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.buttonBackground)
                .cornerRadius(AppConstants.CornerRadius.medium)
        }
        .padding(.bottom, AppConstants.Spacing.large)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(Router())
} 