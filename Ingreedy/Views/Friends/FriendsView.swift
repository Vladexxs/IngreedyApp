import SwiftUI
import Kingfisher

struct FriendsView: View {
    @EnvironmentObject var friendViewModel: FriendViewModel
    @State private var showAddFriendSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Outgoing Friend Requests Section
                        if !friendViewModel.outgoingRequests.isEmpty {
                            outgoingRequestsSection
                        }
                        
                        // Incoming Friend Requests Section
                        if !friendViewModel.incomingRequests.isEmpty {
                            incomingRequestsSection
                        }
                        
                        // Friends Section
                        if !friendViewModel.friends.isEmpty {
                            friendsSection
                        }
                        
                        // Empty State
                        if friendViewModel.outgoingRequests.isEmpty && 
                           friendViewModel.incomingRequests.isEmpty && 
                           friendViewModel.friends.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .refreshable {
                    friendViewModel.refreshData()
                }
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendSheet()
                    .environmentObject(friendViewModel)
            }
            .onAppear {
                friendViewModel.refreshData()
            }
            .overlay {
                if friendViewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Friends")
                .font(.title.bold())
                .foregroundColor(AppColors.primary)
            
            Spacer()
            
            // Debug button for testing (remove in production)
            #if DEBUG
            Button(action: {
                friendViewModel.loadTestData()
            }) {
                Image(systemName: "ladybug")
                    .font(.title3)
                    .foregroundColor(.purple)
            }
            #endif
            
            Button(action: {
                showAddFriendSheet = true
            }) {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.card)
        .shadow(color: AppColors.shadow, radius: 2, y: 1)
    }
    
    // MARK: - Outgoing Friend Requests Section
    private var outgoingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.orange)
                
                Text("Sent Requests")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.primary)
                
                Text("(\(friendViewModel.outgoingRequests.count))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            ForEach(friendViewModel.outgoingRequests) { request in
                OutgoingFriendRequestCard(request: request) {
                    friendViewModel.cancelFriendRequest(request.id)
                }
            }
        }
    }
    
    // MARK: - Incoming Friend Requests Section
    private var incomingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.badge.clock")
                    .foregroundColor(AppColors.accent)
                
                Text("Pending Requests")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.primary)
                
                Text("(\(friendViewModel.incomingRequests.count))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accent)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            ForEach(friendViewModel.incomingRequests) { request in
                FriendRequestCard(request: request) { action in
                    switch action {
                    case .accept:
                        friendViewModel.acceptFriendRequest(request)
                    case .reject:
                        friendViewModel.rejectFriendRequest(request)
                    }
                }
            }
        }
    }
    
    // MARK: - Friends Section
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.green)
                
                Text("My Friends")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.primary)
                
                Text("(\(friendViewModel.friends.count))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            ForEach(friendViewModel.friends) { friend in
                FriendCard(friend: friend) {
                    // Remove friend action
                    friendViewModel.removeFriend(friend)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(AppColors.secondary.opacity(0.5))
            
            Text("No friends yet")
                .font(.headline)
                .foregroundColor(AppColors.secondary)
            
            Text("Add friends to start sharing recipes!")
                .font(.subheadline)
                .foregroundColor(AppColors.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Add Friend") {
                showAddFriendSheet = true
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppColors.accent)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Friend Card Component
struct FriendCard: View {
    let friend: User
    let onRemove: () -> Void
    @State private var showRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            if let url = friend.profileImageUrl, !url.isEmpty {
                KFImage(URL(string: url))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.green, lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(friend.fullName.prefix(1))
                            .font(.title.bold())
                            .foregroundColor(AppColors.primary)
                    )
                    .overlay(
                        Circle()
                            .stroke(.green, lineWidth: 2)
                    )
            }
            
            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.fullName)
                        .font(.headline.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Text(friend.email)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondary)
            }
            
            Spacer()
            
            // Options Menu
            Menu {
                Button(role: .destructive) {
                    showRemoveAlert = true
                } label: {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(AppColors.secondary)
            }
        }
        .padding(20)
        .background(AppColors.card)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 4, y: 2)
        .alert("Remove Friend", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("Are you sure you want to remove \(friend.fullName) from your friends?")
        }
    }
}

// MARK: - Outgoing Friend Request Card Component
struct OutgoingFriendRequestCard: View {
    let request: FriendRequest
    let onCancel: () -> Void
    @State private var showCancelAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            if let url = request.fromUserProfileImageUrl, !url.isEmpty {
                KFImage(URL(string: url))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.orange, lineWidth: 2)
                    )
            } else {
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(request.fromUserName.prefix(1))
                            .font(.headline.bold())
                            .foregroundColor(AppColors.primary)
                    )
                    .overlay(
                        Circle()
                            .stroke(.orange, lineWidth: 2)
                    )
            }
            
            // Request Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(request.toUserName)
                        .font(.headline.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Text("Request sent")
                    .font(.caption)
                    .foregroundColor(AppColors.secondary)
                
                Text(request.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(AppColors.secondary.opacity(0.7))
            }
            
            Spacer()
            
            // Cancel Button
            Button("Cancel") {
                showCancelAlert = true
            }
            .font(.caption.bold())
            .foregroundColor(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.red.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(20)
        .background(AppColors.card)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 4, y: 2)
        .alert("Cancel Request", isPresented: $showCancelAlert) {
            Button("Keep", role: .cancel) { }
            Button("Cancel Request", role: .destructive) {
                onCancel()
            }
        } message: {
            Text("Are you sure you want to cancel your friend request to \(request.toUserName)?")
        }
    }
}

#Preview {
    let testViewModel = FriendViewModel()
    testViewModel.loadTestData()
    
    return FriendsView()
        .environmentObject(testViewModel)
} 