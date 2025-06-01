import SwiftUI

@MainActor
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @State private var showRegister = false
    @EnvironmentObject private var router: Router
    @State private var showResetPasswordAlert = false
    @State private var resetEmail = ""
    @State private var showResetPasswordSuccess = false
    @State private var showForgotPassword = false
    
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
                .onChange(of: viewModel.loginModel.email) {
                    viewModel.clearError()
                }
                
                LoginTextField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: $viewModel.loginModel.password,
                    isSecure: true
                )
                .onChange(of: viewModel.loginModel.password) {
                    viewModel.clearError()
                }
                
                LoginButton(action: {
                    viewModel.login()
                })
                
                // Google Sign In button
                GoogleSignInButton {
                    if let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap({ $0.windows })
                        .first(where: { $0.isKeyWindow })?.rootViewController {
                        Task {
                            await viewModel.signInWithGoogle(presentingViewController: rootVC)
                        }
                    }
                }
                
                // Forgot Password? link
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
                
                SignUpLink {
                    showRegister = true
                }
            }
            .padding(.horizontal, AppConstants.Spacing.extraLarge)
            
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
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .onChange(of: viewModel.isLoggedIn) {
            if viewModel.isLoggedIn {
                router.navigate(to: .home)
            }
        }
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


