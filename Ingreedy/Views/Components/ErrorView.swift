import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color.black.opacity(AppConstants.Opacity.background)
                .ignoresSafeArea()
            
            VStack(spacing: AppConstants.Spacing.medium) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: AppConstants.ImageSize.errorIcon))
                    .foregroundColor(AppColors.text)
                
                Text(error.localizedDescription)
                    .foregroundColor(AppColors.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppConstants.Spacing.medium)
                
                if let retryAction = retryAction {
                    Button(action: retryAction) {
                        Text("Retry")
                            .font(.system(size: AppConstants.FontSize.headline))
                            .foregroundColor(AppColors.buttonText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.buttonBackground)
                            .cornerRadius(AppConstants.CornerRadius.medium)
                    }
                    .padding(.top, AppConstants.Spacing.small)
                }
            }
            .padding(AppConstants.Spacing.large)
            .background(AppColors.primary.opacity(AppConstants.Opacity.foreground))
            .cornerRadius(AppConstants.CornerRadius.medium)
        }
    }
} 