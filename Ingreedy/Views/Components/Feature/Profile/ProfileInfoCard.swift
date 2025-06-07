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
                Text(viewModel.user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondary)
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
            if let downloadedImage = viewModel.downloadedProfileImage {
                Image(uiImage: downloadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 56, height: 56)
            } else if let urlString = viewModel.user?.profileImageUrl, 
                      !urlString.isEmpty, 
                      let url = URL(string: urlString) {
                // Profile image için URL'e timestamp ekleyerek fresh data al
                let freshUrl = URL(string: "\(urlString)?t=\(Date().timeIntervalSince1970)")
                
                KFImage(freshUrl)
                    .configureForProfileImage(size: CGSize(width: 112, height: 112))
                    .placeholder {
                        defaultUserImagePlaceholder
                    }
                    .onProgress { receivedSize, totalSize in
                        // Optional: Progress tracking
                    }
                    .onSuccess { result in
                        print("[ProfileInfoCard] Kingfisher loaded image successfully")
                    }
                    .onFailure { error in
                        print("[ProfileInfoCard] Kingfisher failed to load image: \(error.localizedDescription)")
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 56, height: 56)
            } else {
                defaultUserImagePlaceholder
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