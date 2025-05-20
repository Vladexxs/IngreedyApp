import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let favorites: [Int]
    let friends: [Friend]?
    let profileImageUrl: String?
    let createdAt: Date?
}

struct Friend: Codable {
    let fullName: String
    let profileImageUrl: String?
} 