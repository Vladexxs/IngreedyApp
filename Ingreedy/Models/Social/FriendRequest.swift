import Foundation
import FirebaseFirestore

// MARK: - Friend Request Model
struct FriendRequest: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let fromUserName: String
    let fromUserUsername: String
    let toUserName: String
    let toUserUsername: String?
    let fromUserProfileImageUrl: String?
    let toUserProfileImageUrl: String?
    let status: FriendRequestStatus
    let timestamp: Date
    
    // MARK: - Nested Types
    enum FriendRequestStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case accepted = "accepted"
        case rejected = "rejected"
    }
}

// MARK: - Firebase Helper Extension
extension FriendRequest {
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard 
            let fromUserId = data["fromUserId"] as? String,
            let toUserId = data["toUserId"] as? String,
            let fromUserName = data["fromUserName"] as? String,
            let fromUserUsername = data["fromUserUsername"] as? String,
            let toUserName = data["toUserName"] as? String,
            let statusString = data["status"] as? String,
            let status = FriendRequestStatus(rawValue: statusString),
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
        else {
            return nil
        }
        
        self.id = document.documentID
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.fromUserName = fromUserName
        self.fromUserUsername = fromUserUsername
        self.toUserName = toUserName
        self.toUserUsername = data["toUserUsername"] as? String
        self.fromUserProfileImageUrl = data["fromUserProfileImageUrl"] as? String
        self.toUserProfileImageUrl = data["toUserProfileImageUrl"] as? String
        self.status = status
        self.timestamp = timestamp
    }
    
    /// Convert to dictionary for Firebase
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "fromUserName": fromUserName,
            "fromUserUsername": fromUserUsername,
            "toUserName": toUserName,
            "status": status.rawValue,
            "timestamp": Timestamp(date: timestamp)
        ]
        
        if let toUserUsername = toUserUsername {
            dict["toUserUsername"] = toUserUsername
        }
        
        if let fromUserProfileImageUrl = fromUserProfileImageUrl {
            dict["fromUserProfileImageUrl"] = fromUserProfileImageUrl
        }
        
        if let toUserProfileImageUrl = toUserProfileImageUrl {
            dict["toUserProfileImageUrl"] = toUserProfileImageUrl
        }
        
        return dict
    }
} 