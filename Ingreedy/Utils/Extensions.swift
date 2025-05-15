import Foundation

extension String {
    /// E-posta adresinin geçerli olup olmadığını kontrol eder
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    /// Boşlukları ve satır sonlarını temizler, küçük harfe çevirir
    var normalizedEmail: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

// İleride başka extension'lar da buraya eklenebilir 