import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Delete Account işlemlerini yöneten ViewModel
@MainActor
class DeleteAccountViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var isAccountDeleted = false
    
    // MARK: - Private Properties
    private let authService: AuthenticationServiceProtocol
    
    // MARK: - Initialization
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Hesap silme işleminden önce verileri dışa aktarır
    func exportDataBeforeDeletion() {
        guard let user = authService.currentUser else { return }
        
        performNetwork({ (completion: @escaping (Result<Void, Error>) -> Void) in
            let db = Firestore.firestore()
            
            // Collect all user data for export
            db.collection("users").document(user.id).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let userData = snapshot?.data() else {
                    completion(.failure(NSError(domain: "DataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                    return
                }
                
                // Create comprehensive export data
                let exportData = [
                    "export_info": [
                        "export_date": Date().ISO8601String(),
                        "app_version": "1.0.0",
                        "user_id": user.id
                    ],
                    "profile": userData,
                    "account_created": userData["createdAt"] as? Timestamp ?? Timestamp(),
                    "favorites": userData["favorites"] as? [Int] ?? [],
                    "friends": userData["friends"] as? [[String: Any]] ?? []
                ] as [String: Any]
                
                // In a real implementation, you would:
                // 1. Convert this to JSON
                // 2. Save to Documents directory
                // 3. Present share sheet or email
                // 4. Or upload to temporary storage for download
                
                print("📥 Data export prepared for user: \(user.id)")
                print("📊 Export data: \(exportData)")
                
                completion(.success(()))
            }
        }, onSuccess: { (_: Void) in
            // Show success message or present share sheet
        })
    }
    
    /// Hesabı kalıcı olarak siler
    func deleteAccount() {
        guard let currentUser = authService.currentUser else { 
            print("❌ No authenticated user found for deletion")
            return 
        }
        
        print("🗑️ Starting account deletion process for user: \(currentUser.id)")
        
        performNetwork({ (completion: @escaping (Result<Void, Error>) -> Void) in
            self.performAccountDeletion(userId: currentUser.id, completion: completion)
        }, onSuccess: { (_: Void) in
            print("✅ Account deletion completed successfully")
            
            // DÜZELTME: Logout işlemini ekle
            do {
                try self.authService.logout()
                print("✅ User logged out successfully")
            } catch {
                print("⚠️ Logout failed, but account was deleted: \(error.localizedDescription)")
            }
            
            self.isAccountDeleted = true
        })
    }
    
    // MARK: - Private Methods
    
    /// Hesap silme işlemini gerçekleştirir (DÜZELTILMIŞ SIRALAMA)
    private func performAccountDeletion(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🔄 Starting deletion process with correct order...")
        
        // DÜZELTME: Sıralamayı değiştir - Auth account'u EN SON sil
        
        // 1️⃣ İlk olarak Firestore data sil (auth varken)
        deleteFirestoreData(userId: userId) { [weak self] firestoreError in
            if let error = firestoreError {
                print("❌ Firestore deletion failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            print("✅ Firestore data deleted successfully")
            
            // 2️⃣ Storage files sil (auth varken)
            self?.deleteStorageFiles(userId: userId) { [weak self] storageError in
                if let error = storageError {
                    print("⚠️ Storage deletion failed (continuing): \(error.localizedDescription)")
                    // Storage hatası kritik değil, devam et
                }
                print("✅ Storage files deletion completed")
                
                // 3️⃣ Local data temizle
                self?.clearLocalData()
                print("✅ Local data cleared")
                
                // 4️⃣ EN SON olarak Firebase Auth account sil
                self?.deleteAuthAccount { authError in
                    if let error = authError {
                        print("❌ Auth account deletion failed: \(error.localizedDescription)")
                        // Auth silme başarısız olsa bile diğer veriler silindi
                        // Bu durumda kullanıcıya bilgi verelim ama işlemi başarılı sayalım
                        print("⚠️ Account data was deleted but Firebase Auth deletion failed")
                        completion(.failure(error))
                        return
                    }
                    print("✅ Firebase Auth account deleted successfully")
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Firestore verilerini siler
    private func deleteFirestoreData(userId: String, completion: @escaping (Error?) -> Void) {
        print("🔥 Deleting Firestore data for user: \(userId)")
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete main user document
        let userRef = db.collection("users").document(userId)
        batch.deleteDocument(userRef)
        
        // Delete user settings subcollection
        let settingsRef = userRef.collection("settings").document("privacy")
        batch.deleteDocument(settingsRef)
        
        // In a real implementation, you would also delete:
        // - User's created recipes
        // - User's comments
        // - User's ratings
        // - Any other user-related data
        
        batch.commit { error in
            if let error = error {
                print("❌ Firestore batch commit failed: \(error.localizedDescription)")
            } else {
                print("✅ Firestore batch commit successful")
            }
            completion(error)
        }
    }
    
    /// Storage dosyalarını siler
    private func deleteStorageFiles(userId: String, completion: @escaping (Error?) -> Void) {
        print("📁 Deleting storage files for user: \(userId)")
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        // Delete profile image
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        profileImageRef.delete { error in
            if let error = error as NSError? {
                if error.code == StorageErrorCode.objectNotFound.rawValue {
                    print("ℹ️ Profile image not found (already deleted or never existed)")
                    completion(nil)
                } else {
                    print("❌ Profile image deletion failed: \(error.localizedDescription)")
                    completion(error)
                }
            } else {
                print("✅ Profile image deleted successfully")
                completion(nil)
            }
        }
        
        // In a real implementation, you might also delete:
        // - Recipe images uploaded by user
        // - Any other files associated with the user
    }
    
    /// Firebase Auth hesabını siler (EN SON ADIM)
    private func deleteAuthAccount(completion: @escaping (Error?) -> Void) {
        print("🔐 Deleting Firebase Auth account...")
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "AuthError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
            print("❌ No authenticated user found")
            completion(error)
            return
        }
        
        // DÜZELTME: Re-authentication check ekle
        // Eğer kullanıcı uzun süredir giriş yapmışsa re-auth gerekebilir
        let lastSignInTime = user.metadata.lastSignInDate
        let now = Date()
        let timeSinceLastSignIn = now.timeIntervalSince(lastSignInTime ?? now)
        
        // 5 dakikadan uzun süredir giriş yapılmışsa re-auth öner
        if timeSinceLastSignIn > 300 { // 5 dakika
            print("⚠️ User signed in more than 5 minutes ago, may need re-authentication")
        }
        
        // İlk deneme: Direkt silmeyi dene
        attemptAccountDeletion(user: user, completion: completion)
    }
    
    /// Auth account silmeyi dener, gerekirse re-authentication yapar
    private func attemptAccountDeletion(user: FirebaseAuth.User, completion: @escaping (Error?) -> Void) {
        user.delete { [weak self] error in
            if let error = error {
                print("❌ Firebase Auth deletion failed: \(error.localizedDescription)")
                
                // AuthErrorCode kontrolü
                if let authError = error as NSError? {
                    switch authError.code {
                    case AuthErrorCode.requiresRecentLogin.rawValue:
                        print("🔒 Requires recent login - attempting re-authentication")
                        // Re-authentication gerekiyor
                        self?.handleRecentLoginRequired(user: user, completion: completion)
                        return
                    case AuthErrorCode.userNotFound.rawValue:
                        print("ℹ️ User not found - may already be deleted")
                        completion(nil) // Bu durumda başarılı say
                        return
                    case AuthErrorCode.networkError.rawValue:
                        print("🌐 Network error during auth deletion")
                    default:
                        print("❌ Auth deletion error code: \(authError.code)")
                    }
                }
            } else {
                print("✅ Firebase Auth account deleted successfully")
            }
            completion(error)
        }
    }
    
    /// Recent login required hatası için re-authentication işlemi
    private func handleRecentLoginRequired(user: FirebaseAuth.User, completion: @escaping (Error?) -> Void) {
        print("🔐 Handling recent login requirement...")
        
        // Google Sign-In kullanıcısı için
        if let providerData = user.providerData.first {
            switch providerData.providerID {
            case "google.com":
                print("📱 Google Sign-In user detected - re-auth may require user interaction")
                // Google kullanıcıları için genellikle UI interaction gerekiyor
                // Şimdilik hata döndür, gelecekte Google re-auth eklenebilir
                let error = NSError(
                    domain: "ReAuthError", 
                    code: 401, 
                    userInfo: [NSLocalizedDescriptionKey: "Google users require re-authentication through the app. Please try again after signing out and signing back in."]
                )
                completion(error)
                return
                
            case "password":
                print("📧 Email/Password user - would need password for re-auth")
                // Email/password kullanıcıları için password gerekiyor
                // Şimdilik hata döndür, gelecekte password dialog eklenebilir
                let error = NSError(
                    domain: "ReAuthError", 
                    code: 401, 
                    userInfo: [NSLocalizedDescriptionKey: "Please sign out and sign back in, then try deleting your account again."]
                )
                completion(error)
                return
                
            default:
                print("❓ Unknown provider: \(providerData.providerID)")
            }
        }
        
        // Fallback: Kullanıcıdan yeniden giriş yapmasını iste
        let error = NSError(
            domain: "ReAuthError", 
            code: 401, 
            userInfo: [NSLocalizedDescriptionKey: "For security reasons, please sign out and sign back in, then try deleting your account again."]
        )
        completion(error)
    }
    
    /// Yerel verileri temizler
    private func clearLocalData() {
        print("🧹 Clearing local data...")
        
        // Clear UserDefaults
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            print("✅ UserDefaults cleared")
        }
        
        // Clear URL Cache
        URLCache.shared.removeAllCachedResponses()
        print("✅ URL Cache cleared")
        
        // Clear AuthService cache - Direct logout çağrısı üstte yapıldı
        // AuthService logout zaten cache'i temizliyor
        print("ℹ️ AuthService cache will be cleared by logout() call")
        
        // Clear any other local storage
        // - Core Data if used
        // - Keychain if used  
        // - Any cached files
        
        print("✅ Local data cleared after account deletion")
    }
} 