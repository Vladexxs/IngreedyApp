import Foundation
import FirebaseAuth
import Combine

class FirebaseAuthenticationService: AuthenticationServiceProtocol {
    static let shared = FirebaseAuthenticationService()
    private let auth = Auth.auth()
    
    var currentUser: User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        return createUserFromFirebaseUser(firebaseUser)
    }
    
    func login(email: String, password: String) async throws -> User {
        let normalizedEmail = email.normalizedEmail
        let result = try await auth.signIn(withEmail: normalizedEmail, password: password)
        return createUserFromFirebaseUser(result.user)
    }
    
    func register(email: String, password: String, fullName: String) async throws -> User {
        let normalizedEmail = email.normalizedEmail
        let result = try await auth.createUser(withEmail: normalizedEmail, password: password)
        
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        return createUserFromFirebaseUser(result.user, fullName: fullName)
    }
    
    func logout() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        let normalizedEmail = email.normalizedEmail
        try await auth.sendPasswordReset(withEmail: normalizedEmail)
    }
    
    private func createUserFromFirebaseUser(_ firebaseUser: FirebaseAuth.User, fullName: String? = nil) -> User {
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            fullName: fullName ?? firebaseUser.displayName ?? ""
        )
    }
}