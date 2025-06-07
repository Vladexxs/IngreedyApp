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
        // Cache'i kontrol et ve gerekirse temizle
        if let timestamp = cacheTimestamp, Date().timeIntervalSince(timestamp) > cacheExpirationInterval {
            print("[AuthService] Cache expired, clearing cached user")
            cachedUser = nil
            cacheTimestamp = nil
        }
        
        // Cache'den döndürme yerine her zaman fresh data al
        guard let firebaseUser = auth.currentUser else { 
            cachedUser = nil
            cacheTimestamp = nil
            return nil 
        }
        
        // Her zaman Firestore'dan fresh data al
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
        print("[AuthService] Updating cached user: \(user.fullName), username: \(user.username ?? "nil")")
        cachedUser = user
        cacheTimestamp = Date()
        
        // Also update Firebase Auth displayName if changed
        if let firebaseUser = auth.currentUser, firebaseUser.displayName != user.fullName {
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = user.fullName
            changeRequest.commitChanges { error in
                if let error = error {
                    print("[AuthService] Failed to update displayName: \(error.localizedDescription)")
                } else {
                    print("[AuthService] Firebase Auth displayName updated successfully")
                }
            }
        }
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
            "updatedAt": FieldValue.serverTimestamp(),
            "hasCompletedSetup": true
        ]
        
        print("💾 Saving user data to Firestore: \(userData)")
        
        try await db.collection("users").document(user.uid).setData(userData)
        
        print("✅ User document created successfully")
        
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
        print("[AuthService] User logged out and cache completely cleared")
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
            createdAt: nil,
            hasCompletedSetup: false
        )
    }
    
    // Ensure Firestore user document exists for Google Sign-In users
    func ensureFirestoreUserDocument(for firebaseUser: FirebaseAuth.User, fullName: String? = nil) async throws -> Bool {
        print("🔍 [ensureFirestoreUserDocument] Starting for user: \(firebaseUser.uid)")
        print("📧 [ensureFirestoreUserDocument] Email: \(firebaseUser.email ?? "nil")")
        print("👤 [ensureFirestoreUserDocument] Display Name: \(firebaseUser.displayName ?? "nil")")
        print("📝 [ensureFirestoreUserDocument] Full Name parameter: \(fullName ?? "nil")")
        
        let docRef = db.collection("users").document(firebaseUser.uid)
        
        do {
            let doc = try await docRef.getDocument()
            print("📄 [ensureFirestoreUserDocument] Document exists: \(doc.exists)")
            
            if !doc.exists {
                print("🆕 [ensureFirestoreUserDocument] Creating new user document...")
                // Create new user document without username - user will set it up later
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
                
                print("💾 [ensureFirestoreUserDocument] User data to save: \(userData)")
                try await docRef.setData(userData)
                print("✅ [ensureFirestoreUserDocument] New user document created, needs username setup")
                return true // User needs username setup
            } else {
                print("📋 [ensureFirestoreUserDocument] Existing user found, checking setup status...")
                // Check if existing user has completed setup
                let data = doc.data()
                let hasCompletedSetup = data?["hasCompletedSetup"] as? Bool ?? false
                let username = data?["username"] as? String ?? ""
                
                print("🔧 [ensureFirestoreUserDocument] hasCompletedSetup: \(hasCompletedSetup)")
                print("👤 [ensureFirestoreUserDocument] existing username: '\(username)'")
                
                let needsSetup = !hasCompletedSetup || username.isEmpty
                print("🎯 [ensureFirestoreUserDocument] User needs setup: \(needsSetup)")
                
                return needsSetup // Return true if user needs setup
            }
        } catch {
            print("❌ [ensureFirestoreUserDocument] Error: \(error.localizedDescription)")
            if error.localizedDescription.contains("permission") || error.localizedDescription.contains("insufficient") {
                print("⚠️ [ensureFirestoreUserDocument] Warning: Cannot create/check Firestore user document due to permissions")
                // Don't throw error for Google Sign-In, just log the warning
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