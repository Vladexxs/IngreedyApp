import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel: RegisterViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        _viewModel = StateObject(wrappedValue: RegisterViewModel())
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppConstants.Spacing.large) {
                    RegisterHeaderView()
                    
                    LoginTextField(
                        title: "Full Name",
                        placeholder: "Enter your full name",
                        text: $viewModel.registerModel.fullName,
                        isSecure: false
                    )
                    
                    LoginTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $viewModel.registerModel.email,
                        isSecure: false
                    )
                    
                    LoginTextField(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $viewModel.registerModel.password,
                        isSecure: true
                    )
                    
                    LoginTextField(
                        title: "Confirm Password",
                        placeholder: "Confirm your password",
                        text: $viewModel.registerModel.confirmPassword,
                        isSecure: true
                    )
                    
                    RegisterButton(action: viewModel.register)
                    
                    LoginLink {
                        dismiss()
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.extraLarge)
            }
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            if let error = viewModel.error {
                ErrorView(error: error, retryAction: nil)
            }
        }
    }
}

#Preview {
    RegisterView()
} 