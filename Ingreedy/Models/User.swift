import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var fullName: String
    let username: String?
    let favorites: [Int]
    let friends: [Friend]?
    let profileImageUrl: String?
    let createdAt: Date?
    
    // Initialize with all parameters including username
    init(id: String, email: String, fullName: String, username: String? = nil, favorites: [Int] = [], friends: [Friend]? = nil, profileImageUrl: String? = nil, createdAt: Date? = nil) {
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

struct Friend: Codable {
    let fullName: String
    let profileImageUrl: String?
} 