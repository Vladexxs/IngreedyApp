import Foundation
import Combine

class RegisterViewModel: BaseViewModel {
    @Published var registerModel: RegisterModel = RegisterModel(
        email: "",
        password: "",
        confirmPassword: "",
        fullName: ""
    )
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
    }
    
    func register() {
        guard registerModel.password == registerModel.confirmPassword else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Passwords do not match"]))
            return
        }
        
        Task {
            do {
                isLoading = true
                error = nil
                _ = try await authService.register(
                    email: registerModel.email,
                    password: registerModel.password,
                    fullName: registerModel.fullName
                )
                isLoading = false
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    func clearError() {
        error = nil
    }
}