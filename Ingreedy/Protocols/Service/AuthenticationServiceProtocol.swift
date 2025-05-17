import Foundation
import Combine

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, fullName: String) async throws -> User
    func logout() throws
    func resetPassword(email: String) async throws
    var currentUser: User? { get }
}

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let fullName: String
    var favorites: [Int] = []
    var friends: [String] = []
    var profileImageUrl: String? = nil
}