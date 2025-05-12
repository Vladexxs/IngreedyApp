import Foundation
import FirebaseAuth
import Combine

class FirebaseAuthenticationService: AuthenticationServiceProtocol {
    static let shared = FirebaseAuthenticationService()
    private let auth = Auth.auth()
    
    var currentUser: User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            fullName: firebaseUser.displayName ?? ""
        )
    }
    
    func login(email: String, password: String) async throws -> User {
        let normalizedEmail = normalizeEmail(email)
        let result = try await auth.signIn(withEmail: normalizedEmail, password: password)
        return User(
            id: result.user.uid,
            email: result.user.email ?? "",
            fullName: result.user.displayName ?? ""
        )
    }
    
    func register(email: String, password: String, fullName: String) async throws -> User {
        let normalizedEmail = normalizeEmail(email)
        let result = try await auth.createUser(withEmail: normalizedEmail, password: password)
        
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        return User(
            id: result.user.uid,
            email: result.user.email ?? "",
            fullName: fullName
        )
    }
    
    func logout() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        let normalizedEmail = normalizeEmail(email)
        try await auth.sendPasswordReset(withEmail: normalizedEmail)
    }
    
    func isUserRegistered(email: String) async throws -> Bool {
        // This method will not be used for email validation
        // We'll rely on Firebase's default behavior
        return true
    }
    
    private func normalizeEmail(_ email: String) -> String {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedEmail.lowercased()
    }
}