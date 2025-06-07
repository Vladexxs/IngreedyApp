import Foundation

// MARK: - Friend Model
struct Friend: Codable, Identifiable, Equatable {
    let id: String?
    let fullName: String
    let username: String?
    let profileImageUrl: String?
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        fullName: String,
        username: String? = nil,
        profileImageUrl: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.profileImageUrl = profileImageUrl
    }
    
    // MARK: - Equatable
    static func == (lhs: Friend, rhs: Friend) -> Bool {
        return lhs.id == rhs.id &&
               lhs.fullName == rhs.fullName &&
               lhs.username == rhs.username &&
               lhs.profileImageUrl == rhs.profileImageUrl
    }
} 