import Foundation

// MARK: - User Model
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var fullName: String
    var username: String?
    let favorites: [Int]
    let friends: [Friend]?
    let profileImageUrl: String?
    let createdAt: Date?
    var hasCompletedSetup: Bool
    
    // MARK: - Initializer
    init(
        id: String,
        email: String,
        fullName: String,
        username: String? = nil,
        favorites: [Int] = [],
        friends: [Friend]? = nil,
        profileImageUrl: String? = nil,
        createdAt: Date? = nil,
        hasCompletedSetup: Bool = false
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.username = username
        self.favorites = favorites
        self.friends = friends
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.hasCompletedSetup = hasCompletedSetup
    }
    
    // MARK: - Equatable
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.fullName == rhs.fullName &&
               lhs.username == rhs.username &&
               lhs.favorites == rhs.favorites &&
               lhs.friends == rhs.friends &&
               lhs.profileImageUrl == rhs.profileImageUrl &&
               lhs.hasCompletedSetup == rhs.hasCompletedSetup
    }
} 