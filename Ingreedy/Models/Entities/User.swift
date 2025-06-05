import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    var fullName: String
    let username: String?
    let favorites: [Int]
    let friends: [Friend]?
    let profileImageUrl: String?
    let createdAt: Date?
    
    // MARK: - Initializer
    init(
        id: String,
        email: String,
        fullName: String,
        username: String? = nil,
        favorites: [Int] = [],
        friends: [Friend]? = nil,
        profileImageUrl: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.username = username
        self.favorites = favorites
        self.friends = friends
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
    }
} 