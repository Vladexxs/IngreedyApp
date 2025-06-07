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
                
                isLoading = false
                isLoggedIn = true
                loginSuccess = true
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
            
            print("🚀 [GoogleSignIn] Starting Google Sign-In process...")
            
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = userAuthentication.user.idToken?.tokenString else {
                print("❌ [GoogleSignIn] Failed to get Google ID Token")
                handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Google ID Token."]))
                return
            }
            
            // Get user's full name from Google
            let fullName = userAuthentication.user.profile?.name ?? ""
            print("👤 [GoogleSignIn] Google profile name: '\(fullName)'")
            print("📧 [GoogleSignIn] Google email: '\(userAuthentication.user.profile?.email ?? "nil")'")
            
            let accessToken = userAuthentication.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            print("🔥 [GoogleSignIn] Signing in with Firebase...")
            // Sign in with Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            
            print("✅ [GoogleSignIn] Firebase sign-in successful for user: \(authResult.user.uid)")
            print("📧 [GoogleSignIn] Firebase user email: \(authResult.user.email ?? "nil")")
            print("👤 [GoogleSignIn] Firebase user displayName: \(authResult.user.displayName ?? "nil")")
            
            // Update user's display name if it's empty
            if authResult.user.displayName?.isEmpty ?? true {
                print("🔄 [GoogleSignIn] Updating Firebase displayName...")
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = fullName
                try await changeRequest.commitChanges()
                print("✅ [GoogleSignIn] Firebase displayName updated")
            }
            
            // Ensure Firestore user document exists and check setup status
            if let user = Auth.auth().currentUser {
                print("🔍 [GoogleSignIn] Checking Firestore user document...")
                let userNeedsSetup = try await FirebaseAuthenticationService.shared.ensureFirestoreUserDocument(for: user, fullName: fullName)
                
                print("🎯 [GoogleSignIn] User needs setup: \(userNeedsSetup)")
                
                isLoading = false
                isLoggedIn = true
                
                if userNeedsSetup {
                    print("🔧 [GoogleSignIn] Setting needsUsernameSetup = true")
                    needsUsernameSetup = true
                } else {
                    print("✅ [GoogleSignIn] User setup complete, navigating to home")
                    loginSuccess = true
                }
            }
            
        } catch {
            print("❌ [GoogleSignIn] Error: \(error.localizedDescription)")
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
