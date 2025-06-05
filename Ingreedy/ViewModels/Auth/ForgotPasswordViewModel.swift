import Foundation
import Combine

@MainActor
class ForgotPasswordViewModel: BaseViewModel {
    @Published var forgotPasswordModel: ForgotPasswordModel = ForgotPasswordModel()
    @Published var resetSuccess: Bool = false
    @Published var successMessage: String = ""
    
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
    }
    
    func sendResetEmail() {
        guard validateFields() else { return }
        
        Task {
            do {
                isLoading = true
                error = nil
                
                try await authService.resetPassword(email: forgotPasswordModel.email)
                
                isLoading = false
                resetSuccess = true
                successMessage = "A password reset link has been sent to your email address. Please check your inbox."
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    private func validateFields() -> Bool {
        clearError()
        
        guard !forgotPasswordModel.email.isEmpty else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address"]))
            return false
        }
        
        guard forgotPasswordModel.isValid else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"]))
            return false
        }
        
        return true
    }
    
    // MARK: - Field Validation Helpers
    
    var emailErrorMessage: String? {
        guard !forgotPasswordModel.email.isEmpty else { return nil }
        return forgotPasswordModel.isValid ? nil : "Please enter a valid email address"
    }
} 