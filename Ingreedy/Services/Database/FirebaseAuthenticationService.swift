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
    
    func register(email: String, password: String, fullName: String, username: String) async throws -> User {
        print("🚀 Starting registration process...")
        print("📧 Email: \(email)")
        print("👤 Full Name: \(fullName)")
        print("🔖 Username: \(username)")
        
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔄 Normalized username: '\(normalizedUsername)'")
        
        // Check username availability before creating auth user
        let isAvailable = try await checkUsernameAvailability(username: normalizedUsername)
        guard isAvailable else {
            print("❌ Username '\(normalizedUsername)' is already taken!")
            throw NSError(domain: "AuthError", code: 409, userInfo: [NSLocalizedDescriptionKey: "This username is already taken"])
        }
        
        print("✅ Username is available, proceeding with Firebase Auth...")
        
        // Create Firebase Auth user
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authResult.user
        
        print("🔥 Firebase Auth user created: \(user.uid)")
        
        // Update display name
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        print("📝 Display name updated")
        
        // Create user document in Firestore
        let userData: [String: Any] = [
            "email": email.lowercased(),
            "fullName": fullName,
            "username": normalizedUsername,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        print("💾 Saving user data to Firestore: \(userData)")
        
        try await db.collection("users").document(user.uid).setData(userData)
        
        print("✅ User document created successfully")
        
        return User(
            id: user.uid,
            email: email,
            fullName: fullName,
            username: normalizedUsername
        )
    }
    
    func logout() throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        let normalizedEmail = email.normalizedEmail
        try await auth.sendPasswordReset(withEmail: normalizedEmail)
    }
    
    func checkUsernameAvailability(username: String) async throws -> Bool {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 Checking username availability for: '\(normalizedUsername)'")
        
        do {
            let query = db.collection("users").whereField("username", isEqualTo: normalizedUsername)
            let snapshot = try await query.getDocuments()
            
            print("📊 Query results: \(snapshot.documents.count) documents found")
            
            // Debug: Print found usernames
            for doc in snapshot.documents {
                let data = doc.data()
                let foundUsername = data["username"] as? String ?? "nil"
                print("📝 Found existing username: '\(foundUsername)' in document: \(doc.documentID)")
            }
            
            let isAvailable = snapshot.documents.isEmpty
            print("✅ Username '\(normalizedUsername)' is \(isAvailable ? "AVAILABLE" : "TAKEN")")
            
            return isAvailable
        } catch {
            print("❌ Error checking username availability: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func createUserFromFirebaseUser(_ firebaseUser: FirebaseAuth.User, fullName: String? = nil, username: String? = nil) -> User {
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            fullName: fullName ?? firebaseUser.displayName ?? "",
            username: username,
            favorites: [],
            friends: [],
            profileImageUrl: nil,
            createdAt: nil
        )
    }
    
    // Ensure Firestore user document exists for Google Sign-In users
    func ensureFirestoreUserDocument(for firebaseUser: FirebaseAuth.User, fullName: String? = nil) async throws {
        let docRef = db.collection("users").document(firebaseUser.uid)
        
        do {
            let doc = try await docRef.getDocument()
            if !doc.exists {
                // Generate a unique username for Google Sign-In users
                let baseUsername = (firebaseUser.email?.components(separatedBy: "@").first ?? "user").lowercased()
                let uniqueUsername = try await generateUniqueUsername(baseUsername: baseUsername)
                
                let userData: [String: Any] = [
                    "id": firebaseUser.uid,
                    "email": firebaseUser.email ?? "",
                    "fullName": fullName ?? firebaseUser.displayName ?? "",
                    "username": uniqueUsername,
                    "createdAt": FieldValue.serverTimestamp(),
                    "favorites": [],
                    "friends": [],
                    "profileImageUrl": ""
                ]
                try await docRef.setData(userData)
            }
        } catch {
            if error.localizedDescription.contains("permission") || error.localizedDescription.contains("insufficient") {
                print("⚠️ Warning: Cannot create/check Firestore user document due to permissions")
                // Don't throw error for Google Sign-In, just log the warning
                return
            }
            throw error
        }
    }
    
    private func generateUniqueUsername(baseUsername: String) async throws -> String {
        var counter = 0
        var candidateUsername = baseUsername
        
        while !(try await checkUsernameAvailability(username: candidateUsername)) {
            counter += 1
            candidateUsername = "\(baseUsername)\(counter)"
            
            // Prevent infinite loop
            if counter > 100 {
                candidateUsername = "\(baseUsername)\(Int.random(in: 1000...9999))"
                break
            }
        }
        
        return candidateUsername
    }
}