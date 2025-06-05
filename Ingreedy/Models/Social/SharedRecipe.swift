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

// MARK: - Extensions
extension SentSharedRecipe {
    /// Convert to dictionary for Firebase
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "toUserId": toUserId,
            "recipeId": recipeId,
            "timestamp": timestamp
        ]
        
        if let toUserName = toUserName {
            dict["toUserName"] = toUserName
        }
        
        if let reaction = reaction {
            dict["reaction"] = reaction.rawValue
        }
        
        return dict
    }
}

extension ReceivedSharedRecipe {
    /// Convert to dictionary for Firebase
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "fromUserId": fromUserId,
            "recipeId": recipeId,
            "timestamp": timestamp
        ]
        
        if let fromUserName = fromUserName {
            dict["fromUserName"] = fromUserName
        }
        
        if let reaction = reaction {
            dict["reaction"] = reaction.rawValue
        }
        
        return dict
    }
} 