import SwiftUI

@MainActor
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.background,
                    AppColors.card.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accent, AppColors.accent.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primary)
                            
                            Text("Sign in to your account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Form
                    VStack(spacing: 24) {
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
                        
                        // Forgot Password Link
                        HStack {
                            Spacer()
                            Button(action: {
                                showForgotPassword = true
                            }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(.top, -8)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        ModernButton(
                            title: "Sign In",
                            action: {
                                viewModel.login()
                            },
                            icon: "arrow.right.circle.fill",
                            style: .primary,
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.loginModel.isValid
                        )
                        
                        // Divider
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
                        
                        // Google Sign In
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
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.secondary)
                        
                        Button(action: {
                            showRegister = true
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            
            // Error Overlay
            if let error = viewModel.error {
                VStack {
                    Spacer()
                    ErrorToast(
                        message: error.localizedDescription,
                        onDismiss: {
                            viewModel.clearError()
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
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


