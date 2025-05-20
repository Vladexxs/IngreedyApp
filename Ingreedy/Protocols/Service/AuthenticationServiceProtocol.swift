import Foundation
import Combine
// import Ingreedy (if needed for module)

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, fullName: String) async throws -> User
    func logout() throws
    func resetPassword(email: String) async throws
    var currentUser: User? { get }
}
// User struct removed. Use the one from Models/User.swift