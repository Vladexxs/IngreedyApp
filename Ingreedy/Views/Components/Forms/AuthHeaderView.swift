import SwiftUI

struct AuthHeaderView: View {
    let title: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: AppConstants.Spacing.small) {
            Image(systemName: iconName)
                .resizable()
                .frame(width: AppConstants.ImageSize.logo, height: AppConstants.ImageSize.logo)
                .foregroundColor(AppColors.text)
            
            Text(title)
                .font(.system(size: AppConstants.FontSize.title, weight: .bold))
                .foregroundColor(AppColors.text)
        }
        .padding(.bottom, AppConstants.Spacing.extraLarge)
    }
}

// Backward compatibility
struct LoginHeaderView: View {
    var body: some View {
        AuthHeaderView(title: "Ingreedy", iconName: "fork.knife.circle.fill")
    }
}

struct RegisterHeaderView: View {
    var body: some View {
        AuthHeaderView(title: "Create Account", iconName: "person.crop.circle.badge.plus")
    }
} 