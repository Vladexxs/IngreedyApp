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
        let result = try await auth.signIn(withEmail: email, password: password)
        return User(
            id: result.user.uid,
            email: result.user.email ?? "",
            fullName: result.user.displayName ?? ""
        )
    }
    
    func register(email: String, password: String, fullName: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        
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
} 