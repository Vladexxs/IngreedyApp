import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct EnhancedUserSelectionSheet: View {
    let recipeId: Int
    @Environment(\.dismiss) var dismiss
    @StateObject private var friendViewModel = FriendViewModel()
    @State private var allUsers: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddFriendSheet = false
    @State private var searchText = ""
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return allUsers
        } else {
            return allUsers.filter { user in
                user.fullName.localizedCaseInsensitiveContains(searchText) ||
                (user.username?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Add Friend Button
                headerView
                
                // Search Bar
                searchBar
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Friend Requests Section
                        if !friendViewModel.incomingRequests.isEmpty {
                            friendRequestsSection
                        }
                        
                        // Friends Section
                        if !friendViewModel.friends.isEmpty {
                            friendsSection
                        }
                        
                        // Other Users Section
                        otherUsersSection
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendSheet()
                    .environmentObject(friendViewModel)
            }
            .onAppear {
                loadAllUsers()
                friendViewModel.refreshData()
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading users...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(AppColors.accent)
            
            Spacer()
            
            Text("Share Recipe")
                .font(.headline.bold())
                .foregroundColor(AppColors.primary)
            
            Spacer()
            
            Button(action: {
                showAddFriendSheet = true
            }) {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.card)
        .shadow(color: AppColors.shadow, radius: 2, y: 1)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.secondary)
            
            TextField("Search by name, username, or email...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.card)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Friend Requests Section
    private var friendRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.badge.gearshape")
                    .foregroundColor(AppColors.accent)
                
                Text("Friend Requests")
                    .font(.headline.bold())
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.green)
                
                Text("Friends")
                    .font(.headline.bold())
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
            
            ForEach(friendViewModel.friends.filter { friend in
                searchText.isEmpty || 
                friend.fullName.localizedCaseInsensitiveContains(searchText) ||
                (friend.username?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                friend.email.localizedCaseInsensitiveContains(searchText)
            }) { friend in
                UserCard(user: friend, isPriority: true) {
                    Task {
                        await sendRecipe(toUserId: friend.id)
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Other Users Section
    private var otherUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !filteredUsers.isEmpty {
                HStack {
                    Image(systemName: "person.3")
                        .foregroundColor(AppColors.secondary)
                    
                    Text("Other Users")
                        .font(.headline.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                }
                
                ForEach(filteredUsers) { user in
                    UserCard(user: user, isPriority: false) {
                        Task {
                            await sendRecipe(toUserId: user.id)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    func loadAllUsers() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").getDocuments { snapshot, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            allUsers = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                if id == currentUserId { return nil }
                
                // Arkadaş olanları filtrele
                let isFriend = friendViewModel.friends.contains { $0.id == id }
                if isFriend { return nil }
                
                let fullName = data["fullName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let username = data["username"] as? String
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                
                return User(
                    id: id, 
                    email: email, 
                    fullName: fullName, 
                    username: username,
                    favorites: [], 
                    friends: nil, 
                    profileImageUrl: profileImageUrl, 
                    createdAt: nil
                )
            } ?? []
        }
    }

    func sendRecipe(toUserId: String) async {
        let service = SharedRecipeService()
        do {
            try await service.sendRecipe(toUserId: toUserId, recipeId: recipeId)
        } catch {
            // Handle error if needed
        }
    }
}

// MARK: - User Card Component
struct UserCard: View {
    let user: User
    let isPriority: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile Image
                if let url = user.profileImageUrl, !url.isEmpty {
                    KFImage(URL(string: url))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isPriority ? Color.green : AppColors.secondary.opacity(0.3), lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(AppColors.primary.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(user.fullName.prefix(1))
                                .font(.title2.bold())
                                .foregroundColor(AppColors.primary)
                        )
                        .overlay(
                            Circle()
                                .stroke(isPriority ? Color.green : AppColors.secondary.opacity(0.3), lineWidth: 2)
                        )
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.fullName)
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                        
                        if isPriority {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let username = user.username {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundColor(AppColors.accent)
                            .fontWeight(.medium)
                    }
                    
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                }
                
                Spacer()
                
                // Send Icon
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
            }
            .padding(16)
            .background(AppColors.card)
            .cornerRadius(16)
            .shadow(color: AppColors.shadow, radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

