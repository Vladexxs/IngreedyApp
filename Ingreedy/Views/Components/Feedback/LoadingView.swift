import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(AppConstants.Opacity.background)
                .ignoresSafeArea()
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppColors.text)
                Text("Loading...")
                    .foregroundColor(AppColors.text)
                    .padding(.top, AppConstants.Spacing.small)
            }
            .padding(AppConstants.Spacing.large)
            .background(AppColors.primary.opacity(AppConstants.Opacity.foreground))
            .cornerRadius(AppConstants.CornerRadius.medium)
        }
    }
} 