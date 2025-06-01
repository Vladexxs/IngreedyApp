import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel: RegisterViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    
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
                    .onChange(of: viewModel.registerModel.fullName) {
                        viewModel.clearError()
                    }
                    
                    LoginTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $viewModel.registerModel.email,
                        isSecure: false
                    )
                    .onChange(of: viewModel.registerModel.email) {
                        viewModel.clearError()
                    }
                    
                    LoginTextField(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $viewModel.registerModel.password,
                        isSecure: true
                    )
                    .onChange(of: viewModel.registerModel.password) {
                        viewModel.clearError()
                    }
                    
                    LoginTextField(
                        title: "Confirm Password",
                        placeholder: "Confirm your password",
                        text: $viewModel.registerModel.confirmPassword,
                        isSecure: true
                    )
                    .onChange(of: viewModel.registerModel.confirmPassword) {
                        viewModel.clearError()
                    }
                    
                    RegisterButton(action: {
                        viewModel.register()
                        router.navigate(to: .home)
                    })
                    
                    LoginLink {
                        dismiss()
                    }
                }
                .padding(.horizontal, AppConstants.Spacing.extraLarge)
            }
            
            if viewModel.isLoading {
                IngreedyLoadingView()
            }
            
            if let error = viewModel.error {
                IngreedyErrorView(
                    error: error,
                    retryAction: nil,
                    dismissAction: {
                        viewModel.clearError()
                    }
                )
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(Router())
} 