import Foundation

// MARK: - Shared Recipe Service Protocol
protocol SharedRecipeServiceProtocol {
    func sendRecipe(toUserId: String, recipeId: Int) async throws
    func fetchReceivedRecipes() async throws -> [ReceivedSharedRecipe]
    func fetchSentRecipes() async throws -> [SentSharedRecipe]
    func reactToRecipe(receivedRecipeId: String, reaction: ReactionType) async throws
    func reactToRecipe(receivedRecipeId: String, reaction: String) async throws
} 