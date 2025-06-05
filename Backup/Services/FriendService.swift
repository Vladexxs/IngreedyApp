import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Friend Service Implementation
final class FriendService: FirebaseService, FriendServiceProtocol {
    
    // MARK: - Constants
    private enum Collections {
        static let users = "users"
        static let friendRequests = "friendRequests"
    }
    
    private enum Fields {
        static let username = "username"
        static let friends = "friends"
        static let status = "status"
        static let timestamp = "timestamp"
        static let fromUserId = "fromUserId"
        static let toUserId = "toUserId"
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to username: String) async throws -> Bool {
        let currentUserId = try ensureAuthenticated()
        log("Sending friend request to username: @\(username)")
        
        // Find target user by username
        let targetUser = try await findUserByUsername(username)
        let targetUserId = targetUser.id
        
        // Validate request
        try await validateFriendRequest(targetUserId: targetUserId, username: username)
        
        // Get current user data
        let currentUserData = try await getCurrentUserData()
        
        // Create friend request
        let requestData = createFriendRequestData(
            currentUserId: currentUserId,
            targetUserId: targetUserId,
            currentUserData: currentUserData,
            targetUserData: targetUser.firestoreData
        )
        
        try await db.collection(Collections.friendRequests).addDocument(data: requestData)
        log("Friend request sent successfully to @\(username)")
        return true
    }

    // MARK: - Accept Friend Request
    func acceptFriendRequest(_ requestId: String) async throws {
        let currentUserId = try ensureAuthenticated()
        log("Accepting friend request: \(requestId)")
        
        let request = try await validateIncomingFriendRequest(requestId, currentUserId: currentUserId)
        
        let batch = createBatch()
        
        // Update request status
        let requestRef = db.collection(Collections.friendRequests).document(requestId)
        batch.updateData([Fields.status: FriendRequest.FriendRequestStatus.accepted.rawValue], forDocument: requestRef)
        
        // Add to friends lists
        let currentUserRef = userDocument(currentUserId)
        let fromUserRef = userDocument(request.fromUserId)
        
        batch.updateData([Fields.friends: FieldValue.arrayUnion([request.fromUserId])], forDocument: currentUserRef)
        batch.updateData([Fields.friends: FieldValue.arrayUnion([currentUserId])], forDocument: fromUserRef)
        
        try await batch.commit()
        log("Friend request accepted successfully")
    }
    
    // MARK: - Reject Friend Request
    func rejectFriendRequest(_ requestId: String) async throws {
        log("Rejecting friend request: \(requestId)")
        
        let requestRef = db.collection(Collections.friendRequests).document(requestId)
        try await requestRef.updateData([Fields.status: FriendRequest.FriendRequestStatus.rejected.rawValue])
        
        log("Friend request rejected successfully")
    }
    
    // MARK: - Cancel Friend Request
    func cancelFriendRequest(_ requestId: String) async throws {
        let currentUserId = try ensureAuthenticated()
        log("Canceling friend request: \(requestId)")
        
        let requestRef = db.collection(Collections.friendRequests).document(requestId)
        let requestDoc = try await requestRef.getDocument()
        
        guard let requestData = requestDoc.data(),
              let fromUserId = requestData[Fields.fromUserId] as? String,
              fromUserId == currentUserId else {
            throw ServiceError.unauthorized("cancel friend request")
        }
        
        try await requestRef.delete()
        log("Friend request canceled successfully")
    }
    
    // MARK: - Fetch Friend Requests
    func fetchIncomingFriendRequests() async throws -> [FriendRequest] {
        let currentUserId = try ensureAuthenticated()
        log("Fetching incoming friend requests")
        
        let query = createFriendRequestQuery(field: Fields.toUserId, value: currentUserId)
        let snapshot = try await query.getDocuments()
        
        let requests = snapshot.documents.compactMap { parseDocument($0, as: FriendRequest.self) }
        log("Found \(requests.count) incoming friend requests")
        return requests
    }
    
    func fetchOutgoingFriendRequests() async throws -> [FriendRequest] {
        let currentUserId = try ensureAuthenticated()
        log("Fetching outgoing friend requests")
        
        let query = createFriendRequestQuery(field: Fields.fromUserId, value: currentUserId)
        let snapshot = try await query.getDocuments()
        
        let requests = snapshot.documents.compactMap { parseDocument($0, as: FriendRequest.self) }
        log("Found \(requests.count) outgoing friend requests")
        return requests
    }
    
    // MARK: - Fetch User Friends
    func fetchUserFriends() async throws -> [User] {
        let currentUserId = try ensureAuthenticated()
        log("Fetching user friends")
        
        let userDoc = try await userDocument(currentUserId).getDocument()
        
        guard let userData = userDoc.data(),
              let friendIds = userData[Fields.friends] as? [String] else {
            log("No friends found for user")
            return []
        }
        
        var friends: [User] = []
        
        for friendId in friendIds {
            if let friend = try await fetchUserById(friendId) {
                friends.append(friend)
            }
        }
        
        log("Found \(friends.count) friends")
        return friends
    }
    
    // MARK: - Remove Friend
    func removeFriend(_ friendId: String) async throws {
        let currentUserId = try ensureAuthenticated()
        log("Removing friend: \(friendId)")
        
        let batch = createBatch()
        
        let currentUserRef = userDocument(currentUserId)
        let friendRef = userDocument(friendId)
        
        batch.updateData([Fields.friends: FieldValue.arrayRemove([friendId])], forDocument: currentUserRef)
        batch.updateData([Fields.friends: FieldValue.arrayRemove([currentUserId])], forDocument: friendRef)
        
        try await batch.commit()
        log("Friend removed successfully")
    }
    
    // MARK: - Real-time Listeners
    func listenToIncomingFriendRequests(completion: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration? {
        return createFriendRequestListener(field: Fields.toUserId, completion: completion)
    }
    
    func listenToOutgoingFriendRequests(completion: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration? {
        return createFriendRequestListener(field: Fields.fromUserId, completion: completion)
    }
}

// MARK: - Private Helper Methods
private extension FriendService {
    
    func findUserByUsername(_ username: String) async throws -> (id: String, firestoreData: [String: Any]) {
        let query = db.collection(Collections.users)
            .whereField(Fields.username, isEqualTo: username.lowercased())
        
        let snapshot = try await query.getDocuments()
        
        guard let targetUserDoc = snapshot.documents.first else {
            throw ServiceError.notFound("User with username: @\(username)")
        }
        
        return (id: targetUserDoc.documentID, firestoreData: targetUserDoc.data())
    }
    
    func validateFriendRequest(targetUserId: String, username: String) async throws {
        let currentUserId = try ensureAuthenticated()
        
        // Check self-request
        if targetUserId == currentUserId {
            throw ServiceError.operationFailed("Cannot send friend request to yourself")
        }
        
        // Check if already friends
        if try await checkIfAlreadyFriends(with: targetUserId) {
            throw ServiceError.alreadyExists("Friendship with @\(username)")
        }
        
        // Check for pending request
        if try await checkForPendingRequest(with: targetUserId) {
            throw ServiceError.alreadyExists("Pending friend request to @\(username)")
        }
    }
    
    func getCurrentUserData() async throws -> [String: Any] {
        let currentUserId = try ensureAuthenticated()
        let currentUserDoc = try await userDocument(currentUserId).getDocument()
        
        guard let userData = currentUserDoc.data() else {
            throw ServiceError.notFound("Current user data")
        }
        
        return userData
    }
    
    func createFriendRequestData(
        currentUserId: String,
        targetUserId: String,
        currentUserData: [String: Any],
        targetUserData: [String: Any]
    ) -> [String: Any] {
        return [
            Fields.fromUserId: currentUserId,
            Fields.toUserId: targetUserId,
            "fromUserName": currentUserData["fullName"] as? String ?? "",
            "fromUserUsername": currentUserData[Fields.username] as? String ?? "",
            "fromUserProfileImageUrl": currentUserData["profileImageUrl"] as? String ?? "",
            "toUserName": targetUserData["fullName"] as? String ?? "",
            "toUserUsername": targetUserData[Fields.username] as? String ?? "",
            Fields.status: FriendRequest.FriendRequestStatus.pending.rawValue,
            Fields.timestamp: FieldValue.serverTimestamp()
        ]
    }
    
    func validateIncomingFriendRequest(_ requestId: String, currentUserId: String) async throws -> (fromUserId: String, toUserId: String) {
        let requestRef = db.collection(Collections.friendRequests).document(requestId)
        let requestDoc = try await requestRef.getDocument()
        
        guard let requestData = requestDoc.data(),
              let fromUserId = requestData[Fields.fromUserId] as? String,
              let toUserId = requestData[Fields.toUserId] as? String,
              toUserId == currentUserId else {
            throw ServiceError.unauthorized("accept this friend request")
        }
        
        return (fromUserId: fromUserId, toUserId: toUserId)
    }
    
    func createFriendRequestQuery(field: String, value: String) -> Query {
        return db.collection(Collections.friendRequests)
            .whereField(field, isEqualTo: value)
            .whereField(Fields.status, isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
            .order(by: Fields.timestamp, descending: true)
    }
    
    func createFriendRequestListener(field: String, completion: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration? {
        guard let currentUserId = currentUserId else {
            log("No authenticated user for friend requests listener", level: .error)
            return nil
        }
        
        log("Setting up friend requests listener")
        
        return createFriendRequestQuery(field: field, value: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.log("Error in friend requests listener: \(error.localizedDescription)", level: .error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.log("No documents in friend requests snapshot", level: .warning)
                    completion([])
                    return
                }
                
                let requests = documents.compactMap { self.parseDocument($0, as: FriendRequest.self) }
                self.log("Friend requests listener fired with \(requests.count) requests")
                completion(requests)
            }
    }
    
    func fetchUserById(_ userId: String) async throws -> User? {
        let friendDoc = try await userDocument(userId).getDocument()
        
        guard let friendData = friendDoc.data() else {
            log("Failed to fetch user data for ID: \(userId)", level: .warning)
            return nil
        }
        
        return User(
            id: userId,
            email: friendData["email"] as? String ?? "",
            fullName: friendData["fullName"] as? String ?? "",
            username: friendData[Fields.username] as? String,
            favorites: friendData["favorites"] as? [Int] ?? [],
            friends: nil,
            profileImageUrl: friendData["profileImageUrl"] as? String,
            createdAt: (friendData["createdAt"] as? Timestamp)?.dateValue()
        )
    }
    
    func checkIfAlreadyFriends(with userId: String) async throws -> Bool {
        let currentUserId = try ensureAuthenticated()
        let userDoc = try await userDocument(currentUserId).getDocument()
        
        guard let userData = userDoc.data(),
              let friends = userData[Fields.friends] as? [String] else {
            return false
        }
        
        return friends.contains(userId)
    }
    
    func checkForPendingRequest(with userId: String) async throws -> Bool {
        let currentUserId = try ensureAuthenticated()
        
        // Check both directions for pending requests
        let query1 = createPendingRequestQuery(from: currentUserId, to: userId)
        let query2 = createPendingRequestQuery(from: userId, to: currentUserId)
        
        let snapshot1 = try await query1.getDocuments()
        let snapshot2 = try await query2.getDocuments()
        
        return !snapshot1.documents.isEmpty || !snapshot2.documents.isEmpty
    }
    
    func createPendingRequestQuery(from fromUserId: String, to toUserId: String) -> Query {
        return db.collection(Collections.friendRequests)
            .whereField(Fields.fromUserId, isEqualTo: fromUserId)
            .whereField(Fields.toUserId, isEqualTo: toUserId)
            .whereField(Fields.status, isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
    }
}

// MARK: - FriendRequest Firestore Extension
extension FriendRequest: FirestoreDecodable {
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let statusString = data["status"] as? String,
              let status = FriendRequestStatus(rawValue: statusString),
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.init(
            id: document.documentID,
            fromUserId: fromUserId,
            toUserId: toUserId,
            fromUserName: data["fromUserName"] as? String ?? "",
            fromUserUsername: data["fromUserUsername"] as? String ?? "",
            fromUserProfileImageUrl: data["fromUserProfileImageUrl"] as? String,
            toUserName: data["toUserName"] as? String ?? "",
            toUserUsername: data["toUserUsername"] as? String ?? "",
            status: status,
            timestamp: timestamp
        )
    }
} 