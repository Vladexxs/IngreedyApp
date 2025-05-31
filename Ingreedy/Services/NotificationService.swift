import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var hasNewSharedRecipe: Bool = false
    
    private var receivedRecipesListener: ListenerRegistration?
    private let db = Firestore.firestore()
    private var router: Router?
    private var isInitialLoad: Bool = true // İlk yükleme flag'i
    
    private init() {
        setupNotifications()
    }
    
    deinit {
        receivedRecipesListener?.remove()
        receivedRecipesListener = nil
    }
    
    // Router'ı inject et
    func setRouter(_ router: Router) {
        self.router = router
        startListening()
    }
    
    // MARK: - Notification Setup
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("[DEBUG] Global notification permission granted")
            } else if let error = error {
                print("[DEBUG] Global notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Firestore Listening
    func startListening() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Önce var olan listener'ı durdur
        stopListening()
        
        // Her yeni listener'da initial load flag'ini reset et
        isInitialLoad = true
        
        let receivedRef = db.collection("users").document(currentUserId)
            .collection("sharedRecipes").document("received")
            .collection("received")
        
        print("[DEBUG] Starting global notification listener for user: \(currentUserId)")
        
        receivedRecipesListener = receivedRef
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("[DEBUG] Global notification listener error: \(error)")
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    // İlk yükleme ise bildirim gösterme
                    if self.isInitialLoad {
                        print("[DEBUG] Initial load - skipping notifications")
                        self.isInitialLoad = false
                        return
                    }
                    
                    // İlk yüklemeden sonra sadece gerçek yeni eklenen dökümanlar için bildirim göster
                    let newlyAddedDocs = snapshot.documentChanges.filter { $0.type == .added }
                    
                    if !newlyAddedDocs.isEmpty {
                        for change in newlyAddedDocs {
                            await self.handleNewRecipe(change.document)
                        }
                    }
                }
            }
    }
    
    func stopListening() {
        receivedRecipesListener?.remove()
        receivedRecipesListener = nil
        print("[DEBUG] Global notification listener stopped")
    }
    
    // MARK: - Handle New Recipe
    private func handleNewRecipe(_ document: QueryDocumentSnapshot) async {
        let data = document.data()
        let fromUserId = data["fromUserId"] as? String ?? ""
        let recipeId = data["recipeId"] as? Int ?? 0
        
        print("[DEBUG] New recipe detected! From: \(fromUserId), Recipe: \(recipeId)")
        
        // Global state'i güncelle
        hasNewSharedRecipe = true
        router?.setNewSharedRecipeNotification(true)
        
        // Bildirim göster
        await showNewRecipeNotification(fromUserId: fromUserId, recipeId: recipeId)
    }
    
    // MARK: - Show Notification
    private func showNewRecipeNotification(fromUserId: String, recipeId: Int) async {
        // Basit bildirim göster (kullanıcı ve tarif detayı almadan)
        let content = UNMutableNotificationContent()
        content.title = "🍽️ Yeni Tarif Geldi!"
        content.body = "Size yeni bir yemek tarifi gönderildi!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "new_recipe_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Hemen göster
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("[DEBUG] Notification sent successfully")
        } catch {
            print("[DEBUG] Failed to send notification: \(error)")
        }
    }
    
    // MARK: - Clear Notification
    func clearNotification() {
        hasNewSharedRecipe = false
        router?.setNewSharedRecipeNotification(false)
        print("[DEBUG] Notifications cleared")
    }
} 