import SwiftUI
import Kingfisher

struct ProfileInfoCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    private func cleanURL(from urlString: String) -> URL? {
        guard !urlString.isEmpty else { return nil }
        
        // Önce decode et, sonra encode et (double encoding'i önlemek için)
        let decoded = urlString.removingPercentEncoding ?? urlString
        guard let encoded = decoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            // Fallback: Direkt URL olarak dene
            return URL(string: urlString)
        }
        
        return url
    }
    
    var body: some View {
        HStack(spacing: 16) {
            profileImageView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.user?.fullName ?? "Kullanıcı Adı")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                
                if let username = viewModel.user?.username, !username.isEmpty {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondary)
                } else {
                    Text(viewModel.user?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondary)
                }
            }
            Spacer()
            Button(action: {
                // Profil detay aksiyonu
            }) {
                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.primary)
                    .padding(10)
                    .background(AppColors.card)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(AppColors.card)
        .cornerRadius(20)
        .shadow(color: AppColors.shadow, radius: 8, y: 4)
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var profileImageView: some View {
        ZStack {
            // Background: Always show URL image if available
            if let urlString = viewModel.user?.profileImageUrl, 
               !urlString.isEmpty, 
               let url = URL(string: urlString) {
                
                            KFImage(url)
                .configureForProfileImage(size: CGSize(width: 112, height: 112))
                    .placeholder {
                        defaultUserImagePlaceholder
                    }
                    .onSuccess { _ in }
                    .onFailure { _ in }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 56, height: 56)
            } else {
                defaultUserImagePlaceholder
            }
            
            // Overlay: Show selected image when uploading
            if let selectedImage = viewModel.selectedImage, viewModel.isUploading {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 56, height: 56)
                    .opacity(viewModel.uploadProgress >= 1.0 ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: viewModel.uploadProgress >= 1.0)
            }
            
            // Progress overlay
            if viewModel.isUploading {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 56, height: 56)
                    .overlay(
                        AnimatedProgressRing(
                            progress: viewModel.uploadProgress,
                            lineWidth: 3,
                            size: 40
                        )
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    private var defaultUserImagePlaceholder: some View {
        Circle()
            .fill(AppColors.accent.opacity(0.2))
            .frame(width: 56, height: 56)
            .overlay(
                Text(String((viewModel.user?.fullName ?? "U").prefix(1)).uppercased())
                    .font(.title)
                    .foregroundColor(AppColors.accent)
            )
    }
} 