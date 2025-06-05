import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

// MARK: - Notification Service Implementation
@MainActor
final class NotificationService: FirebaseService, NotificationServiceProtocol {
    
    // MARK: - Singleton
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var hasNewSharedRecipe: Bool = false
    
    // MARK: - Private Properties
    private var receivedRecipesListener: ListenerRegistration?
    private var router: Router?
    private var isInitialLoad: Bool = true
    
    // MARK: - Constants
    private enum Collections {
        static let users = "users"
        static let sharedRecipes = "sharedRecipes"
        static let received = "received"
    }
    
    private enum Fields {
        static let fromUserId = "fromUserId"
        static let recipeId = "recipeId"
        static let timestamp = "timestamp"
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupNotifications()
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Router Configuration
    func setRouter(_ router: Router) {
        self.router = router
        startListening()
    }
    
    // MARK: - Listener Management
    func startListening() {
        guard let currentUserId = currentUserId else {
            log("No authenticated user for notification listener", level: .warning)
            return
        }
        
        stopListening()
        resetInitialLoadFlag()
        
        log("Starting notification listener for user: \(currentUserId)")
        
        let receivedRef = createReceivedRecipeReference(userId: currentUserId)
        
        receivedRecipesListener = receivedRef
            .order(by: Fields.timestamp, descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    await self?.handleSnapshotUpdate(snapshot, error: error)
                }
            }
    }
    
    func stopListening() {
        receivedRecipesListener?.remove()
        receivedRecipesListener = nil
        log("Notification listener stopped")
    }
    
    // MARK: - Notification Control
    func clearNotification() {
        hasNewSharedRecipe = false
        router?.setNewSharedRecipeNotification(false)
        log("Notifications cleared")
    }
}

// MARK: - Private Helper Methods
@MainActor
private extension NotificationService {
    
    func setupNotifications() {
        Task {
            await requestNotificationPermission()
        }
    }
    
    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                log("Notification permission granted")
            } else {
                log("Notification permission denied", level: .warning)
            }
        } catch {
            log("Notification permission error: \(error.localizedDescription)", level: .error)
        }
    }
    
    func resetInitialLoadFlag() {
        isInitialLoad = true
    }
    
    func createReceivedRecipeReference(userId: String) -> CollectionReference {
        return userDocument(userId)
            .collection(Collections.sharedRecipes)
            .document(Collections.received)
            .collection(Collections.received)
    }
    
    func handleSnapshotUpdate(_ snapshot: QuerySnapshot?, error: Error?) async {
        if let error = error {
            log("Notification listener error: \(error.localizedDescription)", level: .error)
            return
        }
        
        guard let snapshot = snapshot else {
            log("No snapshot received from notification listener", level: .warning)
            return
        }
        
        // Skip notifications on initial load
        if isInitialLoad {
            log("Initial load - skipping notifications")
            isInitialLoad = false
            return
        }
        
        await processNewRecipes(from: snapshot)
    }
    
    func processNewRecipes(from snapshot: QuerySnapshot) async {
        let newlyAddedDocs = snapshot.documentChanges.filter { $0.type == .added }
        
        if !newlyAddedDocs.isEmpty {
            log("Processing \(newlyAddedDocs.count) new recipe(s)")
            
            for change in newlyAddedDocs {
                await handleNewRecipe(change.document)
            }
        }
    }
    
    func handleNewRecipe(_ document: QueryDocumentSnapshot) async {
        let data = document.data()
        let fromUserId = data[Fields.fromUserId] as? String ?? ""
        let recipeId = data[Fields.recipeId] as? Int ?? 0
        
        log("New recipe detected! From: \(fromUserId), Recipe ID: \(recipeId)")
        
        // Update global state
        updateNotificationState()
        
        // Show notification
        await showNewRecipeNotification(fromUserId: fromUserId, recipeId: recipeId)
    }
    
    func updateNotificationState() {
        hasNewSharedRecipe = true
        router?.setNewSharedRecipeNotification(true)
    }
    
    func showNewRecipeNotification(fromUserId: String, recipeId: Int) async {
        let content = createNotificationContent()
        let request = createNotificationRequest(content: content)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            log("Notification sent successfully")
        } catch {
            log("Failed to send notification: \(error.localizedDescription)", level: .error)
        }
    }
    
    func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "🍽️ Yeni Tarif Geldi!"
        content.body = "Size yeni bir yemek tarifi gönderildi!"
        content.sound = .default
        content.badge = 1
        return content
    }
    
    func createNotificationRequest(content: UNMutableNotificationContent) -> UNNotificationRequest {
        let identifier = "new_recipe_\(Date().timeIntervalSince1970)"
        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Show immediately
        )
    }
} 