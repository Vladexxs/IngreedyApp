import SwiftUI

struct RegisterHeaderView: View {
    var body: some View {
        VStack(spacing: AppConstants.Spacing.small) {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .frame(width: AppConstants.ImageSize.logo, height: AppConstants.ImageSize.logo)
                .foregroundColor(AppColors.text)
            
            Text("Create Account")
                .font(.system(size: AppConstants.FontSize.title, weight: .bold))
                .foregroundColor(AppColors.text)
        }
        .padding(.bottom, AppConstants.Spacing.extraLarge)
    }
} 