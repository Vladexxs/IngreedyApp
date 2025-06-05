import Foundation

// MARK: - Authentication Service Protocol
protocol AuthenticationServiceProtocol {
    var currentUser: User? { get }
    
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, fullName: String, username: String) async throws -> User
    func logout() throws
    func resetPassword(email: String) async throws
    func checkUsernameAvailability(username: String) async throws -> Bool
}
