import SwiftUI

struct SignUpLink: View {
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(AppColors.text)
            Button("Sign Up", action: action)
                .foregroundColor(AppColors.text)
                .fontWeight(.bold)
        }
        .padding(.top, AppConstants.Spacing.medium)
    }
} 