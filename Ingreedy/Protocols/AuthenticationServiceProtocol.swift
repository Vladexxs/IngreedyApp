import Foundation
import Combine

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, fullName: String) async throws -> User
    func logout() throws
    func resetPassword(email: String) async throws
    func isUserRegistered(email: String) async throws -> Bool
    var currentUser: User? { get }
}

struct User {
    let id: String
    let email: String
    let fullName: String
}