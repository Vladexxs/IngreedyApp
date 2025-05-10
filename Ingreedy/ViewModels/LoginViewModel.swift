import Foundation
import Combine
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

@MainActor
class LoginViewModel: BaseViewModel {
    @Published var loginModel: LoginModel = LoginModel(email: "", password: "")
    @Published var isLoggedIn: Bool = false
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
    }
    
    func login() {
        Task {
            do {
                await MainActor.run {
                    isLoading = true
                    error = nil
                }
                
                _ = try await authService.login(
                    email: loginModel.email,
                    password: loginModel.password
                )
                
                await MainActor.run {
                    isLoading = false
                    isLoggedIn = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isLoggedIn = false
                    handleError(error)
                }
            }
        }
    }
    
    func clearError() {
        error = nil
    }
    
    func signInWithGoogle(presentingViewController: UIViewController) async {
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = userAuthentication.user.idToken?.tokenString else {
                handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google ID Token alınamadı."]))
                return
            }
            let accessToken = userAuthentication.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            isLoading = true
            error = nil
            _ = try await Auth.auth().signIn(with: credential)
            isLoading = false
            isLoggedIn = true
        } catch {
            isLoading = false
            isLoggedIn = false
            handleError(error)
        }
    }
} 
