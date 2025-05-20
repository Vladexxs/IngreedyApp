import SwiftUI

struct ProfileSideMenu: View {
    @Binding var isShowing: Bool
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ZStack {
            // Background overlay
            if isShowing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
            }
            
            // Side menu content
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Ayarlar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.primary)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(AppColors.primary)
                                .padding(8)
                                .background(AppColors.card)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Menu Items
                    ScrollView {
                        VStack(spacing: 0) {
                            MenuItemView(icon: "person.circle", title: "Profil Düzenle") {
                                // Handle profile edit
                            }
                            
                            MenuItemView(icon: "questionmark.circle", title: "Yardım") {
                                // Handle help
                            }
                            
                            MenuItemView(icon: "info.circle", title: "Hakkında") {
                                // Handle about
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            MenuItemView(icon: "rectangle.portrait.and.arrow.right", title: "Çıkış Yap") {
                                viewModel.logout()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .frame(width: 280)
                .background(AppColors.background)
                .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 0)
            }
            .offset(x: isShowing ? 0 : 280)
        }
        .animation(.spring(), value: isShowing)
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.body)
                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 