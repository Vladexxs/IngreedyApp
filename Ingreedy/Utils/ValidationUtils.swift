import Foundation

struct ValidationUtils {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    static func normalizeEmail(_ email: String) -> String {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedEmail.lowercased()
    }
} 