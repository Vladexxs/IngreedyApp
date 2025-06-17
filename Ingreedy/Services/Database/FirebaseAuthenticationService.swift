import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class FirebaseAuthenticationService: AuthenticationServiceProtocol {
    static let shared = FirebaseAuthenticationService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // Cache for user data to avoid stale data issues
    private var cachedUser: User?
    private var cacheTimestamp: Date?
    private let cacheExpirationInterval: TimeInterval = 300 // 5 dakika
    
    var currentUser: User? {
        // Her çağrıda fresh data al, cache'e güvenme
        guard let firebaseUser = auth.currentUser else { 
            cachedUser = nil
            cacheTimestamp = nil
            return nil 
        }
        
        // Basit user objesini döndür, detaylar Firestore'dan alınacak
        return createUserFromFirebaseUser(firebaseUser)
    }
    
    // Yeni bir method ekle: Cache'li kullanıcıyı al (sadece performans kritik durumlarda)
    var cachedCurrentUser: User? {
        if let cached = cachedUser,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) <= cacheExpirationInterval {
            return cached
        }
        return nil
    }
    
    func updateCurrentUser(_ user: User) {
        cachedUser = user
        cacheTimestamp = Date()
        
        // Also update Firebase Auth displayName if changed
        if let firebaseUser = auth.currentUser, firebaseUser.displayName != user.fullName {
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = user.fullName
            changeRequest.commitChanges { error in
                // Handle error silently or log if needed
            }
        }
    }
    
    func login(email: String, password: String) async throws -> User {
        let normalizedEmail = email.normalizedEmail
        let result = try await auth.signIn(withEmail: normalizedEmail, password: password)
        return createUserFromFirebaseUser(result.user)
    }
    
    func register(email: String, password: String, fullName: String, username: String) async throws -> User {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check username availability before creating auth user
        let isAvailable = try await checkUsernameAvailability(username: normalizedUsername)
        guard isAvailable else {
            throw NSError(domain: "AuthError", code: 409, userInfo: [NSLocalizedDescriptionKey: "This username is already taken"])
        }
        
        // Create Firebase Auth user
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authResult.user
        
        // Update display name
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        // Create user document in Firestore
        let userData: [String: Any] = [
            "email": email.lowercased(),
            "fullName": fullName,
            "username": normalizedUsername,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "hasCompletedSetup": true
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
        
        return User(
            id: user.uid,
            email: email,
            fullName: fullName,
            username: normalizedUsername,
            hasCompletedSetup: true
        )
    }
    
    func logout() throws {
        try auth.signOut()
        // Cache ve timestamp'i tamamen temizle
        cachedUser = nil
        cacheTimestamp = nil
    }
    
    func resetPassword(email: String) async throws {
        let normalizedEmail = email.normalizedEmail
        try await auth.sendPasswordReset(withEmail: normalizedEmail)
    }
    
    func checkUsernameAvailability(username: String) async throws -> Bool {
        let normalizedUsername = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let query = db.collection("users").whereField("username", isEqualTo: normalizedUsername)
            let snapshot = try await query.getDocuments()
            
            let isAvailable = snapshot.documents.isEmpty
            return isAvailable
        } catch {
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
            createdAt: nil,
            hasCompletedSetup: false
        )
    }
    
    // Ensure Firestore user document exists and check if user needs setup
    func ensureFirestoreUserDocument(for firebaseUser: FirebaseAuth.User, fullName: String? = nil) async throws -> Bool {
        let docRef = db.collection("users").document(firebaseUser.uid)
        
        do {
            let doc = try await docRef.getDocument()
            
            if !doc.exists {
                // This should only happen for Google Sign-In users
                // Normal email/password users create their document during registration
                let userData: [String: Any] = [
                    "id": firebaseUser.uid,
                    "email": firebaseUser.email ?? "",
                    "fullName": fullName ?? firebaseUser.displayName ?? "",
                    "username": "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "favorites": [],
                    "friends": [],
                    "profileImageUrl": "",
                    "hasCompletedSetup": false
                ]
                
                try await docRef.setData(userData)
                return true // Google Sign-In users need username setup
            } else {
                let data = doc.data()
                let hasCompletedSetup = data?["hasCompletedSetup"] as? Bool
                let username = data?["username"] as? String ?? ""
                
                // Handle legacy users (users created before hasCompletedSetup field was added)
                if hasCompletedSetup == nil {
                    // If user has a username, they are likely a normal email user who completed registration
                    let isLegacyEmailUser = !username.isEmpty
                    
                    // Update document with hasCompletedSetup field
                    let updateData: [String: Any] = [
                        "hasCompletedSetup": isLegacyEmailUser,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                    
                    try await docRef.updateData(updateData)
                    
                    // Return setup requirement based on username presence
                    let needsSetup = username.isEmpty
                    return needsSetup
                }
                
                // For users with hasCompletedSetup field:
                // - If hasCompletedSetup is true, they don't need setup (normal email users)
                // - If hasCompletedSetup is false OR username is empty, they need setup (Google users or incomplete setup)
                let needsSetup = !(hasCompletedSetup ?? false) || username.isEmpty
                
                return needsSetup
            }
        } catch {
            if error.localizedDescription.contains("permission") || error.localizedDescription.contains("insufficient") {
                return false
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