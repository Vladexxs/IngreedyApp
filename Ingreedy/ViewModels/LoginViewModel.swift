import Foundation
import Combine

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
} 