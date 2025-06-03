import Foundation
import Combine
import FirebaseAuth

@MainActor
class FriendViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var incomingRequests: [FriendRequest] = []
    @Published var outgoingRequests: [FriendRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showAddFriendAlert = false
    @Published var friendUsername: String = ""
    
    private let friendService = FriendService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFriends()
        loadIncomingRequests()
        loadOutgoingRequests()
    }
    
    // MARK: - Load Data
    func loadFriends() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedFriends = try await friendService.fetchUserFriends()
                self.friends = fetchedFriends
            } catch {
                self.errorMessage = "Failed to load friends: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
    
    func loadIncomingRequests() {
        Task {
            do {
                print("🔄 Loading incoming requests...")
                let requests = try await friendService.fetchIncomingFriendRequests()
                print("✅ Loaded \(requests.count) incoming requests")
                for request in requests {
                    print("  - Request from: \(request.fromUserName) (@\(request.fromUserUsername))")
                }
                self.incomingRequests = requests
            } catch {
                print("❌ Failed to load friend requests: \(error.localizedDescription)")
            }
        }
    }
    
    func loadOutgoingRequests() {
        Task {
            do {
                print("🔄 Loading outgoing requests...")
                let requests = try await friendService.fetchOutgoingFriendRequests()
                print("✅ Loaded \(requests.count) outgoing requests")
                for request in requests {
                    print("  - Request to: \(request.toUserName) (@\(request.toUserUsername ?? "unknown"))")
                }
                self.outgoingRequests = requests
            } catch {
                print("❌ Failed to load outgoing friend requests: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Send Friend Request
    func sendFriendRequest() {
        guard !friendUsername.isEmpty else {
            errorMessage = "Please enter a username"
            return
        }
        
        let cleanUsername = friendUsername.hasPrefix("@") ? String(friendUsername.dropFirst()) : friendUsername
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let success = try await friendService.sendFriendRequest(to: cleanUsername)
                if success {
                    self.successMessage = "Friend request sent to @\(cleanUsername)!"
                    self.friendUsername = ""
                    self.showAddFriendAlert = false
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Accept Friend Request
    func acceptFriendRequest(_ request: FriendRequest) {
        Task {
            do {
                try await friendService.acceptFriendRequest(request.id)
                
                // Remove from pending requests
                incomingRequests.removeAll { $0.id == request.id }
                
                // Reload friends list
                loadFriends()
                
                successMessage = "Friend request accepted!"
            } catch {
                errorMessage = "Failed to accept friend request: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Reject Friend Request
    func rejectFriendRequest(_ request: FriendRequest) {
        Task {
            do {
                try await friendService.rejectFriendRequest(request.id)
                
                // Remove from pending requests
                incomingRequests.removeAll { $0.id == request.id }
                
                successMessage = "Friend request rejected"
            } catch {
                errorMessage = "Failed to reject friend request: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Remove Friend
    func removeFriend(_ friend: User) {
        Task {
            do {
                try await friendService.removeFriend(friend.id)
                
                // Remove from friends list
                friends.removeAll { $0.id == friend.id }
                
                successMessage = "Friend removed"
            } catch {
                errorMessage = "Failed to remove friend: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Clear Messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Refresh All Data
    func refreshData() {
        loadFriends()
        loadIncomingRequests()
        loadOutgoingRequests()
    }
    
    // MARK: - Cancel Friend Request
    func cancelFriendRequest(_ requestId: String) {
        Task {
            do {
                try await friendService.cancelFriendRequest(requestId)
                loadOutgoingRequests() // Refresh outgoing requests
                successMessage = "Friend request cancelled successfully"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Load Test Data (for testing UI)
    func loadTestData() {
        // Test incoming requests
        let testIncomingRequest1 = FriendRequest(
            id: "test1",
            fromUserId: "user1",
            toUserId: "currentUser",
            fromUserName: "Ali Yılmaz",
            fromUserUsername: "aliyilmaz",
            toUserName: "Current User",
            toUserUsername: "currentuser",
            fromUserProfileImageUrl: nil,
            status: .pending,
            timestamp: Date()
        )
        
        let testIncomingRequest2 = FriendRequest(
            id: "test2",
            fromUserId: "user2",
            toUserId: "currentUser",
            fromUserName: "Ayşe Demir",
            fromUserUsername: "aysedemir",
            toUserName: "Current User",
            toUserUsername: "currentuser",
            fromUserProfileImageUrl: nil,
            status: .pending,
            timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        // Test outgoing requests
        let testOutgoingRequest1 = FriendRequest(
            id: "test3",
            fromUserId: "currentUser",
            toUserId: "user3",
            fromUserName: "Current User",
            fromUserUsername: "currentuser",
            toUserName: "Mehmet Özkan",
            toUserUsername: "mehmetozkan",
            fromUserProfileImageUrl: nil,
            status: .pending,
            timestamp: Date().addingTimeInterval(-1800) // 30 minutes ago
        )
        
        // Test friends
        let testFriend1 = User(
            id: "friend1",
            email: "zeynep@example.com",
            fullName: "Zeynep Kaya",
            username: "zeynepkaya",
            favorites: [],
            friends: nil,
            profileImageUrl: nil,
            createdAt: Date()
        )
        
        let testFriend2 = User(
            id: "friend2",
            email: "emre@example.com",
            fullName: "Emre Şahin",
            username: "emresahin",
            favorites: [],
            friends: nil,
            profileImageUrl: nil,
            createdAt: Date()
        )
        
        self.incomingRequests = [testIncomingRequest1, testIncomingRequest2]
        self.outgoingRequests = [testOutgoingRequest1]
        self.friends = [testFriend1, testFriend2]
    }
} 