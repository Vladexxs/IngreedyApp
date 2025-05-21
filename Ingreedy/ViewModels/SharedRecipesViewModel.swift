import Foundation
import Combine

@MainActor
class SharedRecipesViewModel: ObservableObject {
    @Published var receivedRecipes: [ReceivedSharedRecipe] = []
    @Published var sentRecipes: [SentSharedRecipe] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let service = SharedRecipeService()
    
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
} 