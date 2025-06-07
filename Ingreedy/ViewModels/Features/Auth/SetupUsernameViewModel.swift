import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class SetupUsernameViewModel: BaseViewModel {
    @Published var isSetupComplete: Bool = false
    
    private let authService: AuthenticationServiceProtocol
    
    init(
        authService: AuthenticationServiceProtocol = FirebaseAuthenticationService.shared
    ) {
        self.authService = authService
        super.init()
    }
    
    func setupUsername(_ username: String) async {
        guard validateUsername(username) else { return }
        
        do {
            isLoading = true
            error = nil
            
            // Check if username is available
            let isAvailable = try await checkUsernameAvailability(username)
            guard isAvailable else {
                handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bu kullanıcı adı zaten alınmış. Lütfen başka bir tane deneyin."]))
                isLoading = false
                return
            }
            
            // Get current user
            guard let currentUser = Auth.auth().currentUser else {
                handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı."]))
                isLoading = false
                return
            }
            
            // Update user document in Firestore
            try await updateUserUsername(userId: currentUser.uid, username: username)
            
            isLoading = false
            isSetupComplete = true
            
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    private func validateUsername(_ username: String) -> Bool {
        clearError()
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedUsername.isEmpty else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı adı boş olamaz."]))
            return false
        }
        
        guard trimmedUsername.count >= 3 else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı adı en az 3 karakter olmalı."]))
            return false
        }
        
        guard trimmedUsername.count <= 20 else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı adı en fazla 20 karakter olabilir."]))
            return false
        }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard trimmedUsername.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir."]))
            return false
        }
        
        return true
    }
    
    private func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let db = Firestore.firestore()
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces).lowercased()
        
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: trimmedUsername)
            .getDocuments()
        
        return snapshot.documents.isEmpty
    }
    
    private func updateUserUsername(userId: String, username: String) async throws {
        let db = Firestore.firestore()
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces).lowercased()
        
        try await db.collection("users").document(userId).updateData([
            "username": trimmedUsername,
            "hasCompletedSetup": true
        ])
        
        // Update AuthService cache with new username
        if var currentUser = authService.currentUser {
            currentUser.username = trimmedUsername
            currentUser.hasCompletedSetup = true
            authService.updateCurrentUser(currentUser)
            print("[SetupUsernameViewModel] AuthService cache updated with username: \(trimmedUsername)")
        }
    }
} 