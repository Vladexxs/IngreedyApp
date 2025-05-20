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
                isLoading = true
                error = nil
                
                _ = try await authService.login(
                    email: loginModel.email,
                    password: loginModel.password
                )
                
                isLoading = false
                isLoggedIn = true
            } catch {
                isLoading = false
                isLoggedIn = false
                handleError(error)
            }
        }
    }
    
    func signInWithGoogle(presentingViewController: UIViewController) async {
        do {
            isLoading = true
            error = nil
            
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = userAuthentication.user.idToken?.tokenString else {
                handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Google ID Token."]))
                return
            }
            
            // Get user's full name from Google
            let fullName = userAuthentication.user.profile?.name ?? ""
            
            let accessToken = userAuthentication.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in with Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Update user's display name if it's empty
            if authResult.user.displayName?.isEmpty ?? true {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                try await changeRequest.commitChanges()
            }
            
            // Ensure Firestore user document exists
            if let user = Auth.auth().currentUser {
                try await FirebaseAuthenticationService.shared.ensureFirestoreUserDocument(for: user, fullName: fullName)
            }
            
            isLoading = false
            isLoggedIn = true
        } catch {
            isLoading = false
            isLoggedIn = false
            handleError(error)
        }
    }
    
    func resetPassword(email: String) async {
        do {
            isLoading = true
            error = nil
            try await authService.resetPassword(email: email)
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
}
