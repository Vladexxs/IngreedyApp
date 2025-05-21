import Foundation

struct ReceivedSharedRecipe: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let recipeId: Int
    var reaction: String? // "like", "neutral", "dislike" veya nil
    let timestamp: Date
} 