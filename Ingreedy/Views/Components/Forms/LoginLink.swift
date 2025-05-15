import SwiftUI

struct LoginLink: View {
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text("Already have an account?")
                .foregroundColor(AppColors.text)
            Button("Login", action: action)
                .foregroundColor(AppColors.text)
                .fontWeight(.bold)
        }
        .padding(.top, AppConstants.Spacing.medium)
    }
} 