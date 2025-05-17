import SwiftUI

struct ProfileInfoCard: View {
    let user: User
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColors.accent.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(user.fullName.prefix(1)).uppercased())
                        .font(.title)
                        .foregroundColor(AppColors.accent)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
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
} 