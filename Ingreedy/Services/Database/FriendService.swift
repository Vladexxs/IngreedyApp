import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

class FriendService: FriendServiceProtocol {
    private let db = Firestore.firestore()
    
    // MARK: - Send Friend Request
    func sendFriendRequest(to username: String) async throws -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "FriendService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Username ile kullanıcıyı bul
        let usersRef = db.collection("users")
        let query = usersRef.whereField("username", isEqualTo: username.lowercased())
        
        let snapshot = try await query.getDocuments()
        
        guard let targetUserDoc = snapshot.documents.first else {
            throw NSError(domain: "FriendService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found with username: @\(username)"])
        }
        
        let targetUserId = targetUserDoc.documentID
        let targetUserData = targetUserDoc.data()
        
        // Kendine arkadaşlık isteği göndermeyi engelle
        if targetUserId == currentUser.uid {
            throw NSError(domain: "FriendService", code: 400, userInfo: [NSLocalizedDescriptionKey: "You cannot send a friend request to yourself"])
        }
        
        // Mevcut arkadaşlık durumunu kontrol et
        let isAlreadyFriend = try await checkIfAlreadyFriends(with: targetUserId)
        if isAlreadyFriend {
            throw NSError(domain: "FriendService", code: 409, userInfo: [NSLocalizedDescriptionKey: "You are already friends with @\(username)"])
        }
        
        // Bekleyen istek var mı kontrol et
        let hasPendingRequest = try await checkForPendingRequest(with: targetUserId)
        if hasPendingRequest {
            throw NSError(domain: "FriendService", code: 409, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent to @\(username)"])
        }
        
        // Mevcut kullanıcının bilgilerini al
        let currentUserDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        guard let currentUserData = currentUserDoc.data() else {
            throw NSError(domain: "FriendService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get current user data"])
        }
        
        // Arkadaşlık isteği oluştur
        let requestData: [String: Any] = [
            "fromUserId": currentUser.uid,
            "toUserId": targetUserId,
            "fromUserName": currentUserData["fullName"] as? String ?? "",
            "fromUserUsername": currentUserData["username"] as? String ?? "",
            "fromUserProfileImageUrl": currentUserData["profileImageUrl"] as? String ?? "",
            "toUserName": targetUserData["fullName"] as? String ?? "",
            "toUserUsername": targetUserData["username"] as? String ?? "",
            "toUserProfileImageUrl": targetUserData["profileImageUrl"] as? String ?? "",
            "status": FriendRequest.FriendRequestStatus.pending.rawValue,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("friendRequests").addDocument(data: requestData)
        return true
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(_ requestId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let requestRef = db.collection("friendRequests").document(requestId)
        let requestDoc = try await requestRef.getDocument()
        
        guard let requestData = requestDoc.data(),
              let fromUserId = requestData["fromUserId"] as? String,
              let toUserId = requestData["toUserId"] as? String,
              toUserId == currentUserId else {
            throw NSError(domain: "FriendService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Invalid friend request"])
        }
        
        // Batch işlemi başlat
        let batch = db.batch()
        
        // İsteği kabul edildi olarak güncelle
        batch.updateData(["status": FriendRequest.FriendRequestStatus.accepted.rawValue], forDocument: requestRef)
        
        // Her iki kullanıcının arkadaş listesine ekle
        let currentUserRef = db.collection("users").document(currentUserId)
        let fromUserRef = db.collection("users").document(fromUserId)
        
        batch.updateData(["friends": FieldValue.arrayUnion([fromUserId])], forDocument: currentUserRef)
        batch.updateData(["friends": FieldValue.arrayUnion([currentUserId])], forDocument: fromUserRef)
        
        try await batch.commit()
    }
    
    // MARK: - Reject Friend Request
    func rejectFriendRequest(_ requestId: String) async throws {
        let requestRef = db.collection("friendRequests").document(requestId)
        try await requestRef.updateData(["status": FriendRequest.FriendRequestStatus.rejected.rawValue])
    }
    
    // MARK: - Fetch Incoming Friend Requests
    func fetchIncomingFriendRequests() async throws -> [FriendRequest] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            return [] 
        }
        
        let query = db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        let requests = snapshot.documents.compactMap { doc in
            return FriendRequest(from: doc)
        }
        
        return requests
    }
    
    // MARK: - Fetch Outgoing Friend Requests
    func fetchOutgoingFriendRequests() async throws -> [FriendRequest] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            return [] 
        }
        
        let query = db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        let requests = snapshot.documents.compactMap { doc in
            return FriendRequest(from: doc)
        }
        
        return requests
    }
    
    // MARK: - Cancel Friend Request
    func cancelFriendRequest(_ requestId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let requestRef = db.collection("friendRequests").document(requestId)
        let requestDoc = try await requestRef.getDocument()
        
        guard let requestData = requestDoc.data(),
              let fromUserId = requestData["fromUserId"] as? String,
              fromUserId == currentUserId else {
            throw NSError(domain: "FriendService", code: 403, userInfo: [NSLocalizedDescriptionKey: "You can only cancel your own friend requests"])
        }
        
        try await requestRef.delete()
    }
    
    // MARK: - Fetch User's Friends (OPTIMIZED - Batch çeken versiyon)
    func fetchUserFriends() async throws -> [User] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            return [] 
        }
        
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        
        guard let userData = userDoc.data(),
              let friendIds = userData["friends"] as? [String],
              !friendIds.isEmpty else {
            return []
        }
        
        // OPTIMIZE: Batch olarak çek, maksimum 30 arkadaş (Firestore 'in' query limiti)
        var friends: [User] = []
        
        // Firestore 'in' query limiti 30, bu yüzden chunklara böl
        let chunkSize = 30
        for chunk in friendIds.chunked(into: chunkSize) {
            let query = db.collection("users").whereField(FieldPath.documentID(), in: chunk)
            let snapshot = try await query.getDocuments()
            
            let chunkFriends = snapshot.documents.compactMap { doc -> User? in
                let data = doc.data()
                return User(
                    id: doc.documentID,
                    email: data["email"] as? String ?? "",
                    fullName: data["fullName"] as? String ?? "",
                    username: data["username"] as? String,
                    favorites: data["favorites"] as? [Int] ?? [],
                    friends: nil,
                    profileImageUrl: data["profileImageUrl"] as? String,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue()
                )
            }
            
            friends.append(contentsOf: chunkFriends)
        }
        
        return friends
    }
    
    // MARK: - Remove Friend
    func removeFriend(_ friendId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let batch = db.batch()
        
        let currentUserRef = db.collection("users").document(currentUserId)
        let friendRef = db.collection("users").document(friendId)
        
        batch.updateData(["friends": FieldValue.arrayRemove([friendId])], forDocument: currentUserRef)
        batch.updateData(["friends": FieldValue.arrayRemove([currentUserId])], forDocument: friendRef)
        
        try await batch.commit()
    }
    
    // MARK: - Helper Methods
    private func checkIfAlreadyFriends(with userId: String) async throws -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let userData = userDoc.data(),
              let friends = userData["friends"] as? [String] else {
            return false
        }
        
        return friends.contains(userId)
    }
    
    private func checkForPendingRequest(with userId: String) async throws -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        
        // Her iki yönde de bekleyen istek var mı kontrol et
        let query1 = db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
        
        let query2 = db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
        
        let snapshot1 = try await query1.getDocuments()
        let snapshot2 = try await query2.getDocuments()
        
        return !snapshot1.documents.isEmpty || !snapshot2.documents.isEmpty
    }
    
    // MARK: - Real-time Listeners
    
    /// Listen to incoming friend requests with real-time updates
    func listenToIncomingFriendRequests(completion: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            return nil
        }
        
        return db.collection("friendRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let requests = documents.compactMap { doc in
                    FriendRequest(from: doc)
                }
                
                completion(requests)
            }
    }
    
    /// Listen to outgoing friend requests with real-time updates
    func listenToOutgoingFriendRequests(completion: @escaping ([FriendRequest]) -> Void) -> ListenerRegistration? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            return nil
        }
        
        return db.collection("friendRequests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: FriendRequest.FriendRequestStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let requests = documents.compactMap { doc in
                    FriendRequest(from: doc)
                }
                
                completion(requests)
            }
    }
} 