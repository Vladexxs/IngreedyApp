import Foundation

struct SentSharedRecipe: Identifiable, Codable {
    let id: String
    let toUserId: String
    let recipeId: Int
    var reaction: String? // "like", "neutral", "dislike" veya nil
    let timestamp: Date
} 