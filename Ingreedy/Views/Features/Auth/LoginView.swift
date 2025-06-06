import SwiftUI

@MainActor
struct LoginView: View {
    // MARK: - ViewModels & State
    @StateObject private var viewModel = LoginViewModel()
    
    // MARK: - Navigation State
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @EnvironmentObject private var router: Router
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundView
            
            ScrollView(showsIndicators: false) {
                mainContentView
            }
            
            if let error = viewModel.error {
                errorOverlayView(error: error)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .onChange(of: viewModel.loginSuccess) { success in
            if success {
                router.navigate(to: .home)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.error != nil)
    }
}

// MARK: - Private Views
private extension LoginView {
    
    var backgroundView: some View {
        AppColors.background
            .ignoresSafeArea()
    }
    
    var mainContentView: some View {
        VStack(spacing: LayoutConstants.mainSpacing) {
            Spacer(minLength: LayoutConstants.topSpacing)
            
            LoginHeaderView()
            
            loginFormView
            
            actionButtonsView
            
            signUpLinkView
            
            Spacer(minLength: LayoutConstants.bottomSpacing)
        }
        .padding(.horizontal, LayoutConstants.horizontalPadding)
    }
    
    var loginFormView: some View {
        VStack(spacing: LayoutConstants.formSpacing) {
            emailTextField
            passwordTextField
            forgotPasswordLink
        }
    }
    
    var emailTextField: some View {
        ModernTextField(
            title: "Email",
            placeholder: "Enter your email address",
            text: $viewModel.loginModel.email,
            icon: "envelope.fill",
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            isValid: viewModel.loginModel.email.isEmpty ? nil : viewModel.loginModel.isEmailValid,
            errorMessage: viewModel.emailErrorMessage
        )
        .onChange(of: viewModel.loginModel.email) { _ in
            viewModel.clearError()
        }
    }
    
    var passwordTextField: some View {
        ModernTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: $viewModel.loginModel.password,
            isSecure: true,
            icon: "lock.fill",
            textContentType: .password,
            isValid: viewModel.loginModel.password.isEmpty ? nil : (viewModel.loginModel.password.count >= 6),
            errorMessage: viewModel.passwordErrorMessage
        )
        .onChange(of: viewModel.loginModel.password) { _ in
            viewModel.clearError()
        }
    }
    
    var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button(action: { showForgotPassword = true }) {
                Text("Forgot Password?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.top, -8)
    }
    
    var actionButtonsView: some View {
        VStack(spacing: LayoutConstants.buttonSpacing) {
            signInButton
            dividerView
            googleSignInButton
        }
    }
    
    var signInButton: some View {
        ModernButton(
            title: "Sign In",
            action: { viewModel.login() },
            icon: "arrow.right.circle.fill",
            style: .primary,
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.loginModel.isValid
        )
    }
    
    var dividerView: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.secondary.opacity(0.3))
            
            Text("or")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.secondary)
                .padding(.horizontal, 16)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppColors.secondary.opacity(0.3))
        }
        .padding(.vertical, 8)
    }
    
    var googleSignInButton: some View {
        ModernGoogleSignInButton(
            action: {
                if let rootVC = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .flatMap({ $0.windows })
                    .first(where: { $0.isKeyWindow })?.rootViewController {
                    Task {
                        await viewModel.signInWithGoogle(presentingViewController: rootVC)
                    }
                }
            },
            isLoading: viewModel.isLoading
        )
    }
    
    var signUpLinkView: some View {
        HStack {
            Text("Don't have an account?")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.secondary)
            
            Button(action: { showRegister = true }) {
                Text("Sign Up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.top, 8)
    }
    
    func errorOverlayView(error: Error) -> some View {
        VStack {
            Spacer()
            ErrorToast(
                message: error.localizedDescription,
                onDismiss: { viewModel.clearError() }
            )
            .padding(.horizontal, LayoutConstants.horizontalPadding)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Design Constants
private enum LayoutConstants {
    static let mainSpacing: CGFloat = 32
    static let topSpacing: CGFloat = 20
    static let bottomSpacing: CGFloat = 40
    static let horizontalPadding: CGFloat = 24
    static let formSpacing: CGFloat = 24
    static let buttonSpacing: CGFloat = 16
}

// Error Toast Component
struct ErrorToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red)
                .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(Router())
}

struct ViewControllerResolver: UIViewControllerRepresentable {
    var onResolve: (UIViewController) -> Void
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            onResolve(viewController)
        }
        return viewController
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// Simple button for Google Sign In with SwiftUI
struct GoogleSignInButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "globe")
                Text("Sign in with Google")
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(8)
        }
    }
}



