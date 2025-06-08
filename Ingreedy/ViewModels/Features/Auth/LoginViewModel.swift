import Foundation
import Combine
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

@MainActor
class LoginViewModel: BaseViewModel {
    @Published var loginModel: LoginModel = LoginModel(email: "", password: "")
    @Published var isLoggedIn: Bool = false
    @Published var loginSuccess: Bool = false
    @Published var needsUsernameSetup: Bool = false
    
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
    }
    
    func login() {
        // Validate fields first
        guard validateFields() else { return }
        
        Task {
            do {
                isLoading = true
                error = nil
                
                _ = try await authService.login(
                    email: loginModel.email,
                    password: loginModel.password
                )
                
                // Check if user needs username setup (similar to Google Sign-In)
                if let firebaseUser = Auth.auth().currentUser {
                    let userNeedsSetup = try await FirebaseAuthenticationService.shared.ensureFirestoreUserDocument(for: firebaseUser)
                    
                    isLoading = false
                    isLoggedIn = true
                    
                    if userNeedsSetup {
                        needsUsernameSetup = true
                    } else {
                        loginSuccess = true
                    }
                } else {
                    isLoading = false
                    isLoggedIn = false
                    handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed. Please try again."]))
                }
            } catch {
                isLoading = false
                isLoggedIn = false
                handleError(error)
            }
        }
    }
    
    private func validateFields() -> Bool {
        clearError()
        
        guard !loginModel.email.isEmpty else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address"]))
            return false
        }
        
        guard !loginModel.password.isEmpty else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter your password"]))
            return false
        }
        
        guard loginModel.isEmailValid else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"]))
            return false
        }
        
        return true
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
            
            // Ensure Firestore user document exists and check setup status
            if let user = Auth.auth().currentUser {
                let userNeedsSetup = try await FirebaseAuthenticationService.shared.ensureFirestoreUserDocument(for: user, fullName: fullName)
                
                isLoading = false
                isLoggedIn = true
                
                if userNeedsSetup {
                    needsUsernameSetup = true
                } else {
                    loginSuccess = true
                }
            }
            
        } catch {
            isLoading = false
            isLoggedIn = false
            handleError(error)
        }
    }
    
    func resetPassword(email: String) async {
        guard !email.isEmpty else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address"]))
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"]))
            return
        }
        
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
    
    // MARK: - Field Validation Helpers
    
    var emailErrorMessage: String? {
        guard !loginModel.email.isEmpty else { return nil }
        return loginModel.isEmailValid ? nil : "Please enter a valid email address"
    }
    
    var passwordErrorMessage: String? {
        guard !loginModel.password.isEmpty else { return nil }
        return loginModel.password.count >= 6 ? nil : "Password must be at least 6 characters"
    }
}
