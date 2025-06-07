import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// Account Settings işlemlerini yöneten ViewModel
@MainActor
class AccountSettingsViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isExporting = false
    @Published var isClearingCache = false
    
    // MARK: - Private Properties
    private let authService: AuthenticationServiceProtocol
    private let storage = UserDefaults.standard
    
    // MARK: - Initialization
    init(authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared) {
        self.authService = authService
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Mevcut kullanıcı bilgilerini yükler
    func loadCurrentUser() {
        currentUser = authService.currentUser
        if let user = currentUser {
            fetchUserFromFirestore(userId: user.id)
        }
    }
    
    /// Kullanıcı verilerini dışa aktarır
    func exportUserData() {
        guard let user = currentUser else { return }
        
        performNetwork({ completion in
            DispatchQueue.main.async {
                self.isExporting = true
            }
            
            // Simulate export process
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                let userData = [
                    "user_id": user.id,
                    "email": user.email,
                    "full_name": user.fullName,
                    "username": user.username ?? "",
                    "created_at": user.createdAt?.ISO8601String() ?? "",
                    "favorites_count": user.favorites.count
                ] as [String: Any]
                
                DispatchQueue.main.async {
                    self.isExporting = false
                    // In real implementation, save to Documents directory or share
                    print("User data exported: \(userData)")
                    completion(.success(()))
                }
            }
        }, onSuccess: { _ in
            // Show success message
        })
    }
    
    /// Cache'i temizler
    func clearCache() {
        performNetwork({ completion in
            DispatchQueue.main.async {
                self.isClearingCache = true
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                // Clear various caches
                URLCache.shared.removeAllCachedResponses()
                
                // Clear UserDefaults cache (if any)
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                DispatchQueue.main.async {
                    self.isClearingCache = false
                    completion(.success(()))
                }
            }
        }, onSuccess: { _ in
            // Show success message
        })
    }
    
    /// Email değiştirme işlemi
    func changeEmail(newEmail: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Re-authenticate user
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: password)
        try await user.reauthenticate(with: credential)
        
        // Update email
        try await user.updateEmail(to: newEmail)
        
        // Update in Firestore
        let db = Firestore.firestore()
        try await db.collection("users").document(user.uid).updateData([
            "email": newEmail
        ])
        
        // Update local user by creating a new User instance
        await MainActor.run {
            if let currentUser = self.currentUser {
                self.currentUser = User(
                    id: currentUser.id,
                    email: newEmail,
                    fullName: currentUser.fullName,
                    username: currentUser.username,
                    favorites: currentUser.favorites,
                    friends: currentUser.friends,
                    profileImageUrl: currentUser.profileImageUrl,
                    createdAt: currentUser.createdAt,
                    hasCompletedSetup: currentUser.hasCompletedSetup
                )
            }
        }
    }
    
    /// Şifre değiştirme işlemi
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Re-authenticate user
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
        try await user.reauthenticate(with: credential)
        
        // Update password
        try await user.updatePassword(to: newPassword)
    }
    
    // MARK: - Private Methods
    
    /// Firestore'dan kullanıcı bilgilerini getirir
    private func fetchUserFromFirestore(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                // Update current user with Firestore data
                let updatedUser = User(
                    id: userId,
                    email: data["email"] as? String ?? self.currentUser?.email ?? "",
                    fullName: data["fullName"] as? String ?? self.currentUser?.fullName ?? "",
                    username: data["username"] as? String,
                    favorites: data["favorites"] as? [Int] ?? [],
                    friends: [], // Simplified for this context
                    profileImageUrl: data["profileImageUrl"] as? String,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                    hasCompletedSetup: data["hasCompletedSetup"] as? Bool ?? false
                )
                
                self.currentUser = updatedUser
            }
        }
    }
}

// MARK: - Extensions

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 