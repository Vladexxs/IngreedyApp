import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseAuthenticationService: AuthenticationServiceProtocol {
    static let shared = FirebaseAuthenticationService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
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
        
        // Create user document in Firestore with all required fields
        let userData: [String: Any] = [
            "id": result.user.uid,
            "email": normalizedEmail,
            "fullName": fullName,
            "createdAt": FieldValue.serverTimestamp(),
            "favorites": [],
            "friends": [],
            "profileImageUrl": ""
        ]
        
        try await db.collection("users").document(result.user.uid).setData(userData)
        
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
            fullName: fullName ?? firebaseUser.displayName ?? "",
            favorites: [],
            friends: [],
            profileImageUrl: nil,
            createdAt: nil
        )
    }
    
    // Ensure Firestore user document exists for Google Sign-In users
    func ensureFirestoreUserDocument(for firebaseUser: FirebaseAuth.User, fullName: String? = nil) async throws {
        let docRef = db.collection("users").document(firebaseUser.uid)
        let doc = try await docRef.getDocument()
        if !doc.exists {
            let userData: [String: Any] = [
                "id": firebaseUser.uid,
                "email": firebaseUser.email ?? "",
                "fullName": fullName ?? firebaseUser.displayName ?? "",
                "createdAt": FieldValue.serverTimestamp(),
                "favorites": [],
                "friends": [],
                "profileImageUrl": ""
            ]
            try await docRef.setData(userData)
        }
    }
}