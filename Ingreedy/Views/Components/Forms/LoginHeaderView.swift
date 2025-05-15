import SwiftUI

struct LoginHeaderView: View {
    var body: some View {
        VStack(spacing: AppConstants.Spacing.small) {
            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .frame(width: AppConstants.ImageSize.logo, height: AppConstants.ImageSize.logo)
                .foregroundColor(AppColors.text)
            
            Text("Ingreedy")
                .font(.system(size: AppConstants.FontSize.title, weight: .bold))
                .foregroundColor(AppColors.text)
        }
        .padding(.bottom, AppConstants.Spacing.extraLarge)
    }
} 