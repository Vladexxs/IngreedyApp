import Foundation
import FirebaseFirestore

// MARK: - Friend Service Protocol
protocol FriendServiceProtocol {
    func sendFriendRequest(to username: String) async throws -> Bool
    func acceptFriendRequest(_ requestId: String) async throws
    func rejectFriendRequest(_ requestId: String) async throws
    func fetchIncomingFriendRequests() async throws -> [FriendRequest]
    func fetchOutgoingFriendRequests() async throws -> [FriendRequest]
    func cancelFriendRequest(_ requestId: String) async throws
    func fetchUserFriends() async throws -> [User]
    func removeFriend(_ friendId: String) async throws
    
    // Real-time listeners
    func listenToIncomingFriendRequests(completion: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration?
    func listenToOutgoingFriendRequests(completion: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration?
} 