import Foundation

// MARK: - Shared Recipe Models

/// Reaction types for shared recipes
enum ReactionType: String, Codable, CaseIterable {
    case like = "like"
    case neutral = "neutral"
    case dislike = "dislike"
    
    var emoji: String {
        switch self {
        case .like: return "👍"
        case .neutral: return "😐"
        case .dislike: return "👎"
        }
    }
}

/// Recipe sent to a friend
struct SentSharedRecipe: Identifiable, Codable {
    let id: String
    let toUserId: String
    let toUserName: String?
    let recipeId: Int
    var reaction: ReactionType?
    let timestamp: Date
}

/// Recipe received from a friend
struct ReceivedSharedRecipe: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let fromUserName: String?
    let recipeId: Int
    var reaction: ReactionType?
    let timestamp: Date
}

 