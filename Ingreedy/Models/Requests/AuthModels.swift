import Foundation

// MARK: - Authentication Models

/// Login form model
struct LoginModel: Codable {
    var email: String
    var password: String
    
    // MARK: - Initializer
    init(email: String = "", password: String = "") {
        self.email = email
        self.password = password
    }
    
    // MARK: - Validation
    var isValid: Bool {
        return !email.isEmpty && 
               !password.isEmpty && 
               email.contains("@") && 
               password.count >= 6
    }
    
    var isEmailValid: Bool {
        return email.contains("@") && email.contains(".")
    }
}

/// Registration form model
struct RegisterModel: Codable {
    var email: String
    var password: String
    var confirmPassword: String
    var fullName: String
    var username: String
    
    // MARK: - Initializer
    init(
        email: String = "",
        password: String = "",
        confirmPassword: String = "",
        fullName: String = "",
        username: String = ""
    ) {
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.fullName = fullName
        self.username = username
    }
    
    // MARK: - Validation
    var isValid: Bool {
        return !email.isEmpty && 
               !password.isEmpty && 
               !fullName.isEmpty &&
               !username.isEmpty &&
               isEmailValid &&
               isPasswordValid &&
               password == confirmPassword &&
               isUsernameValid
    }
    
    var isEmailValid: Bool {
        return email.contains("@") && email.contains(".")
    }
    
    var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    var isUsernameValid: Bool {
        return username.count >= 3 && 
               username.count <= 20 &&
               username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" } &&
               !username.contains(" ")
    }
    
    var isFullNameValid: Bool {
        return fullName.count >= 2
    }
}

/// Forgot Password form model
struct ForgotPasswordModel: Codable {
    var email: String
    
    init(email: String = "") {
        self.email = email
    }
    
    var isValid: Bool {
        return !email.isEmpty && email.contains("@") && email.contains(".")
    }
} 