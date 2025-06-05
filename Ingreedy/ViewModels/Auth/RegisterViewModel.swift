import Foundation
import Combine

@MainActor
class RegisterViewModel: BaseViewModel {
    @Published var registerModel: RegisterModel = RegisterModel(
        email: "",
        password: "",
        confirmPassword: "",
        fullName: "",
        username: ""
    )
    
    @Published var isUsernameChecking = false
    @Published var isUsernameAvailable: Bool? = nil
    @Published var registrationSuccess = false
    
    private let authService: AuthenticationServiceProtocol
    private var usernameCheckTask: Task<Void, Never>?
    
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
        setupUsernameValidation()
    }
    
    deinit {
        usernameCheckTask?.cancel()
    }
    
    private func setupUsernameValidation() {
        // Real-time username availability checking with debounce
        $registerModel
            .map(\.username)
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] username in
                self?.checkUsernameAvailability(username)
            }
            .store(in: &cancellables)
    }
    
    private func checkUsernameAvailability(_ username: String) {
        // Cancel previous task
        usernameCheckTask?.cancel()
        
        guard !username.isEmpty && registerModel.isUsernameValid else {
            isUsernameAvailable = nil
            isUsernameChecking = false
            return
        }
        
        isUsernameChecking = true
        
        usernameCheckTask = Task {
            do {
                let isAvailable = try await authService.checkUsernameAvailability(username: username.lowercased())
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isUsernameAvailable = isAvailable
                        self.isUsernameChecking = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.isUsernameAvailable = nil
                        self.isUsernameChecking = false
                        self.handleError(error)
                    }
                }
            }
        }
    }
    
    func register() {
        // Validate all fields
        guard validateFields() else { return }
        
        Task {
            do {
                isLoading = true
                error = nil
                
                _ = try await authService.register(
                    email: registerModel.email,
                    password: registerModel.password,
                    fullName: registerModel.fullName,
                    username: registerModel.username
                )
                
                isLoading = false
                registrationSuccess = true
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    private func validateFields() -> Bool {
        // Clear previous errors
        clearError()
        
        // Check if passwords match
        guard registerModel.password == registerModel.confirmPassword else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Passwords do not match"]))
            return false
        }
        
        // Check if username is available
        guard isUsernameAvailable == true else {
            if isUsernameAvailable == false {
                handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "This username is already taken"]))
            } else {
                handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please wait for username validation"]))
            }
            return false
        }
        
        // Check if all fields are valid
        guard registerModel.isValid else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please fill all fields correctly"]))
            return false
        }
        
        return true
    }
    
    // MARK: - Field Validation Helpers
    
    var emailErrorMessage: String? {
        guard !registerModel.email.isEmpty else { return nil }
        return registerModel.isEmailValid ? nil : "Please enter a valid email address"
    }
    
    var passwordErrorMessage: String? {
        guard !registerModel.password.isEmpty else { return nil }
        return registerModel.isPasswordValid ? nil : "Password must be at least 6 characters"
    }
    
    var confirmPasswordErrorMessage: String? {
        guard !registerModel.confirmPassword.isEmpty else { return nil }
        return registerModel.password == registerModel.confirmPassword ? nil : "Passwords do not match"
    }
    
    var fullNameErrorMessage: String? {
        guard !registerModel.fullName.isEmpty else { return nil }
        return registerModel.isFullNameValid ? nil : "Full name must be at least 2 characters"
    }
    
    var usernameErrorMessage: String? {
        guard !registerModel.username.isEmpty else { return nil }
        
        if !registerModel.isUsernameValid {
            return "Username must be 3-20 characters, letters, numbers, and underscore only"
        }
        
        if isUsernameChecking {
            return "Checking availability..."
        }
        
        if isUsernameAvailable == false {
            return "This username is already taken"
        }
        
        return nil
    }
}