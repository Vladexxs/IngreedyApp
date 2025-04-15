import SwiftUI

struct LoginButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Login")
                .font(.headline)
                .foregroundColor(AppColors.buttonText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.buttonBackground)
                .cornerRadius(AppConstants.CornerRadius.large)
                .shadow(
                    color: AppConstants.Shadow.small,
                    radius: AppConstants.Shadow.radius,
                    x: 0,
                    y: AppConstants.Shadow.y
                )
        }
        .padding(.top, AppConstants.Spacing.large)
    }
} 