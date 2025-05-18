import SwiftUI

struct ProfileInfoCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    private func cleanURL(from urlString: String) -> URL? {
        guard !urlString.isEmpty,
              let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let originalUrl = URL(string: encoded) else {
            return nil
        }
        
        var components = URLComponents(url: originalUrl, resolvingAgainstBaseURL: false)
        components?.port = nil
        let cleanUrl = components?.url ?? originalUrl
        return cleanUrl
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let downloadedImage = viewModel.downloadedProfileImage {
                Image(uiImage: downloadedImage)
                    .resizable()
                    .clipShape(Circle())
                    .frame(width: 56, height: 56)
            } else if let urlString = viewModel.user?.profileImageUrl, let cleanUrl = cleanURL(from: urlString) {
                AsyncImage(url: cleanUrl) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .onAppear {
                                // AsyncImage başarılı olursa, bunu da viewModel'e aktarabiliriz (isteğe bağlı)
                                // viewModel.downloadedProfileImage = image.asUIImage() // UIImage'e çevirme gerekebilir
                            }
                    } else if let error = phase.error {
                        defaultUserImagePlaceholder
                            .onAppear {
                                print("ProfileInfoCard AsyncImage Hatası: \(error.localizedDescription)")
                            }
                    } else {
                        ProgressView()
                    }
                }
                .id(cleanUrl.absoluteString)
                .clipShape(Circle())
                .frame(width: 56, height: 56)
                .onAppear {
                    print("ProfileInfoCard AsyncImage için Clean URL: \(cleanUrl.absoluteString)")
                }
            } else {
                defaultUserImagePlaceholder
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.user?.fullName ?? "Kullanıcı Adı")
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                Text("Recipe Developer") // veya user.role
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

// SwiftUI Image'ı UIImage'e çevirmek için bir extension (gerekirse)
/*
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
*/ 