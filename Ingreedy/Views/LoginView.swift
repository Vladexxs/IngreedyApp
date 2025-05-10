import SwiftUI

@MainActor
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @State private var showRegister = false
    @EnvironmentObject private var router: Router
    
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
                .onChange(of: viewModel.loginModel.email) { _ in
                    viewModel.clearError()
                }
                
                LoginTextField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: $viewModel.loginModel.password,
                    isSecure: true
                )
                .onChange(of: viewModel.loginModel.password) { _ in
                    viewModel.clearError()
                }
                
                LoginButton(action: {
                    viewModel.login()
                })
                
                // Google ile Giriş Yap butonu
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
                
                SignUpLink {
                    showRegister = true
                }
            }
            .padding(.horizontal, AppConstants.Spacing.extraLarge)
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            if let error = viewModel.error {
                ErrorView(
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
        .onChange(of: viewModel.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
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

// GoogleSignInButton SwiftUI için basit bir buton
struct GoogleSignInButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "globe")
                Text("Google ile Giriş Yap")
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(8)
        }
    }
} 


