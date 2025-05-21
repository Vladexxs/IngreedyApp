import Foundation

struct SentSharedRecipe: Identifiable, Codable {
    let id: String
    let toUserId: String
    let recipeId: Int
    let timestamp: Date
} 