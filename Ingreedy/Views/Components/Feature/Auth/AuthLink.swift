import SwiftUI

struct AuthLink: View {
    let questionText: String
    let actionText: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(questionText)
                .foregroundColor(AppColors.text)
            Button(actionText, action: action)
                .foregroundColor(AppColors.text)
                .fontWeight(.bold)
        }
        .padding(.top, AppConstants.Spacing.medium)
    }
}

// Backward compatibility
struct LoginLink: View {
    let action: () -> Void
    
    var body: some View {
        AuthLink(
            questionText: "Already have an account?",
            actionText: "Login",
            action: action
        )
    }
}

struct SignUpLink: View {
    let action: () -> Void
    
    var body: some View {
        AuthLink(
            questionText: "Don't have an account?",
            actionText: "Sign Up",
            action: action
        )
    }
} 