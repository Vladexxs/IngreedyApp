import Foundation

// MARK: - Friend Model
struct Friend: Codable, Identifiable {
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
} 