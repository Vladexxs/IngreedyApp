import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @State private var showRegister = false
    
    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel())
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppConstants.Spacing.large) {
                LoginHeaderView()
                
                LoginTextField(
                    title: "Email",
                    placeholder: "Enter your email",
                    text: $viewModel.loginModel.email,
                    isSecure: false
                )
                
                LoginTextField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: $viewModel.loginModel.password,
                    isSecure: true
                )
                
                LoginButton(action: viewModel.login)
                
                SignUpLink {
                    showRegister = true
                }
            }
            .padding(.horizontal, AppConstants.Spacing.extraLarge)
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            if let error = viewModel.error {
                ErrorView(error: error, retryAction: nil)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }
}

#Preview {
    LoginView()
} 
