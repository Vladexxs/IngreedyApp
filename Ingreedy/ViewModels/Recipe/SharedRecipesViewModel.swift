import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SharedRecipesViewModel: ObservableObject {
    @Published var receivedRecipes: [ReceivedSharedRecipe] = []
    @Published var sentRecipes: [SentSharedRecipe] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userCache: [String: User] = [:] // userId -> User
    @Published var recipeCache: [Int: Recipe] = [:] // recipeId -> Recipe
    @Published var newRecipeReceived: Bool = false // Deprecated - use global NotificationService
    
    private let service = SharedRecipeService()
    private let customSession: URLSession
    private let db = Firestore.firestore()
    var router: Router? // Router referansı (public)
    
    init(router: Router? = nil) {
        self.router = router
        let config = URLSessionConfiguration.default
        config.httpShouldUsePipelining = false
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.customSession = URLSession(configuration: config)
    }
    
    // Bana gönderilen tarifleri çek (tek seferlik fetch)
    func loadReceivedRecipes() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let receivedRef = db.collection("users").document(currentUserId)
                .collection("sharedRecipes").document("received")
                .collection("received")
            
            let snapshot = try await receivedRef.order(by: "timestamp", descending: true).getDocuments()
            
            let recipes = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                let fromUserId = data["fromUserId"] as? String ?? ""
                let recipeId = data["recipeId"] as? Int ?? 0
                let reaction = data["reaction"] as? String
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                
                return ReceivedSharedRecipe(
                    id: id,
                    fromUserId: fromUserId,
                    recipeId: recipeId,
                    reaction: reaction,
                    timestamp: timestamp
                )
            }
            
            receivedRecipes = recipes
        } catch {
            errorMessage = "Alınan tarifler yüklenemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Yeni tarif bildirimini temizle (deprecated)
    func clearNewRecipeAlert() {
        newRecipeReceived = false
    }
    
    // Benim gönderdiğim tarifleri çek
    func loadSentRecipes() async {
        isLoading = true
        errorMessage = nil
        do {
            let recipes = try await service.fetchSentRecipes()
            sentRecipes = recipes
            // Mevcut kullanıcı bilgilerini yükle
            if let currentUserId = Auth.auth().currentUser?.uid {
                await fetchUserIfNeeded(userId: currentUserId)
            }
        } catch {
            errorMessage = "Gönderdiğim tarifler yüklenemedi: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // Gelen tarife emoji tepkisi ver
    func reactToRecipe(receivedRecipeId: String, reaction: String) async {
        do {
            try await service.reactToRecipe(receivedRecipeId: receivedRecipeId, reaction: reaction)
            // Local güncelleme
            if let index = receivedRecipes.firstIndex(where: { $0.id == receivedRecipeId }) {
                receivedRecipes[index].reaction = reaction
            }
        } catch {
            errorMessage = "Tepki gönderilemedi."
        }
    }
    
    // Tarif gönderme (isteğe bağlı, UI'de kullanmak istersem)
    func sendRecipe(toUserId: String, recipeId: Int) async {
        do {
            try await service.sendRecipe(toUserId: toUserId, recipeId: recipeId)
            // Gönderilenler listesini güncellemek için tekrar çekebilirsiniz
            await loadSentRecipes()
        } catch {
            errorMessage = "Tarif gönderilemedi."
        }
    }
    
    // Kullanıcıyı çek
    func fetchUserIfNeeded(userId: String) async {
        if userCache[userId] != nil { return }
        
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            guard let data = doc.data() else { return }
            
            let profileImageUrl = data["profileImageUrl"] as? String
            
            // URL'yi kontrol et ve düzelt
            var finalProfileImageUrl = profileImageUrl
            if let url = profileImageUrl, !url.isEmpty {
                if let urlComponents = URLComponents(string: url) {
                    var components = urlComponents
                    components.scheme = "https"
                    components.port = nil
                    if let newUrl = components.url?.absoluteString {
                        finalProfileImageUrl = newUrl
                    }
                }
            }
            
            let user = User(
                id: userId,
                email: data["email"] as? String ?? "",
                fullName: data["fullName"] as? String ?? "",
                favorites: data["favorites"] as? [Int] ?? [],
                friends: [],
                profileImageUrl: finalProfileImageUrl,
                createdAt: nil
            )
            
            userCache[userId] = user
        } catch {
            // print("[DEBUG] Firestore'dan kullanıcı çekilirken hata: \(error.localizedDescription)")
        }
    }
    
    // Tarif çek
    func fetchRecipeIfNeeded(recipeId: Int) async {
        if recipeCache[recipeId] != nil { return }
        let service = RecipeService()
        let recipesResult = await withCheckedContinuation { continuation in
            service.fetchRecipes { result in
                continuation.resume(returning: result)
            }
        }
        if case .success(let recipes) = recipesResult {
            if let recipe = recipes.first(where: { $0.id == recipeId }) {
                recipeCache[recipeId] = recipe
            }
        }
    }
} 
