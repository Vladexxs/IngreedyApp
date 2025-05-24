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
    
    private let service = SharedRecipeService()
    private let customSession: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpShouldUsePipelining = false
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.customSession = URLSession(configuration: config)
    }
    
    // Bana gönderilen tarifleri çek
    func loadReceivedRecipes() async {
        isLoading = true
        errorMessage = nil
        do {
            let recipes = try await service.fetchReceivedRecipes()
            receivedRecipes = recipes
        } catch {
            errorMessage = "Bana gönderilen tarifler yüklenemedi."
        }
        isLoading = false
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
                print("[DEBUG] Mevcut kullanıcı ID: \(currentUserId)")
                await fetchUserIfNeeded(userId: currentUserId)
            } else {
                print("[DEBUG] Mevcut kullanıcı bulunamadı")
            }
        } catch {
            errorMessage = "Gönderdiğim tarifler yüklenemedi."
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
    
    // Tarif gönderme (isteğe bağlı, UI'de kullanmak isterseniz)
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
        print("[DEBUG] fetchUserIfNeeded başladı - userId: \(userId)")
        if userCache[userId] != nil { 
            print("[DEBUG] Kullanıcı cache'de bulundu: \(userCache[userId]?.fullName ?? "isim yok")")
            print("[DEBUG] Cache'deki profil resmi URL: \(userCache[userId]?.profileImageUrl ?? "URL yok")")
            return 
        }
        
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            guard let data = doc.data() else { 
                print("[DEBUG] Firestore'da kullanıcı bulunamadı: \(userId)")
                return 
            }
            
            print("[DEBUG] Firestore'dan gelen veri: \(data)")
            let profileImageUrl = data["profileImageUrl"] as? String
            print("[DEBUG] Firestore'dan gelen profil resmi URL: \(profileImageUrl ?? "URL yok")")
            
            // URL'yi kontrol et ve düzelt
            var finalProfileImageUrl = profileImageUrl
            if let url = profileImageUrl, !url.isEmpty {
                if let urlComponents = URLComponents(string: url) {
                    var components = urlComponents
                    components.scheme = "https" // HTTPS kullan
                    // Port numarasını kaldır (443 varsayılan HTTPS portu)
                    components.port = nil
                    if let newUrl = components.url?.absoluteString {
                        finalProfileImageUrl = newUrl
                        print("[DEBUG] URL düzeltildi: \(newUrl)")
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
            
            print("[DEBUG] Oluşturulan kullanıcı nesnesi:")
            print("- ID: \(user.id)")
            print("- İsim: \(user.fullName)")
            print("- Profil Resmi URL: \(user.profileImageUrl ?? "URL yok")")
            
            userCache[userId] = user
            print("[DEBUG] Kullanıcı cache'e eklendi")
        } catch {
            print("[DEBUG] Firestore'dan kullanıcı çekilirken hata: \(error.localizedDescription)")
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