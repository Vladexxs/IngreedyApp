import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

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
    
    // Real-time listeners
    private var incomingRequestsListener: ListenerRegistration?
    private var outgoingRequestsListener: ListenerRegistration?
    
    init() {
        setupRealTimeListeners()
        loadFriends()
    }
    
    deinit {
        // Clean up listeners
        incomingRequestsListener?.remove()
        outgoingRequestsListener?.remove()
        print("🧹 FriendViewModel: Cleaned up real-time listeners")
    }
    
    // MARK: - Setup Real-time Listeners
    private func setupRealTimeListeners() {
        print("🔄 FriendViewModel: Setting up real-time listeners")
        
        // Listen to incoming requests
        incomingRequestsListener = friendService.listenToIncomingFriendRequests { [weak self] requests in
            DispatchQueue.main.async {
                print("✅ FriendViewModel: Received \(requests.count) incoming requests via listener")
                self?.incomingRequests = requests
            }
        }
        
        // Listen to outgoing requests
        outgoingRequestsListener = friendService.listenToOutgoingFriendRequests { [weak self] requests in
            DispatchQueue.main.async {
                print("✅ FriendViewModel: Received \(requests.count) outgoing requests via listener")
                self?.outgoingRequests = requests
            }
        }
        
        print("✅ FriendViewModel: Real-time listeners setup completed")
    }
    
    // MARK: - Restart Listeners (when user changes)
    func restartListeners() {
        print("🔄 FriendViewModel: Restarting real-time listeners")
        incomingRequestsListener?.remove()
        outgoingRequestsListener?.remove()
        setupRealTimeListeners()
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
    
    // These methods are now handled by real-time listeners
    // Keep them for backward compatibility but they don't need to do anything
    func loadIncomingRequests() {
        // Real-time listener handles this automatically
        print("📡 FriendViewModel: Incoming requests are handled by real-time listener")
    }
    
    func loadOutgoingRequests() {
        // Real-time listener handles this automatically
        print("📡 FriendViewModel: Outgoing requests are handled by real-time listener")
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
                    // No need to manually refresh - real-time listener will update UI
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
                
                // Real-time listener will automatically remove from pending requests
                // Reload friends list to show the new friend
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
                
                // Real-time listener will automatically remove from pending requests
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
        // Only refresh friends - real-time listeners handle requests automatically
        loadFriends()
        print("🔄 FriendViewModel: Refreshed friends list - requests handled by real-time listeners")
    }
    
    // MARK: - Cancel Friend Request
    func cancelFriendRequest(_ requestId: String) {
        Task {
            do {
                try await friendService.cancelFriendRequest(requestId)
                // Real-time listener will automatically remove from outgoing requests
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