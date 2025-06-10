import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct SharedRecipesView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: SharedRecipesViewModel
    @StateObject private var friendViewModel = FriendViewModel()
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var selectedTab = 0
    @State private var selectedRecipe: Recipe? = nil
    @State private var selectedRecipeForEmoji: ReceivedSharedRecipe? = nil
    @State private var flyingEmoji: String? = nil
    @State private var flyingEmojiPosition: CGPoint = .zero
    @State private var showFriendsView = false

    let segmentTitles = ["Received", "Sent"]
    
    init() {
        // Router'ı sonradan inject edeceğiz
        self._viewModel = StateObject(wrappedValue: SharedRecipesViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Segment Control
                    segmentControl
                    
                    // Content
                    contentView
                }
                .onTapGesture { } // Emoji menüsünü kapatmak için
                .onAppear {
                    setupViewModel()
                }
                
                // Animated Emoji Menu System
                emojiMenuOverlay
                
                // Flying emoji animation
                flyingEmojiView
                
                // Navigation
                navigationLink
            }
        }
        .sheet(isPresented: $showFriendsView) {
            FriendsView()
                .environmentObject(friendViewModel)
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Shared Recipes")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.primary)
                
                // New recipe notification
                if notificationService.hasNewSharedRecipe {
                    Button(action: {
                        notificationService.clearNotification()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.white)
                                .font(.caption)
                            Text("New!")
                                .foregroundColor(.white)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.accent)
                        .cornerRadius(12)
                        .shadow(color: AppColors.accent.opacity(0.3), radius: 4, y: 2)
                    }
                }
            }
            
            Spacer()
            
            // Friends Button
            Button(action: { 
                showFriendsView.toggle() 
            }) {
                ZStack {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.primary)
                    
                    // Notification badge for friend requests
                    if !friendViewModel.incomingRequests.isEmpty {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Text("\(friendViewModel.incomingRequests.count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 24)
    }
    
    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(0..<segmentTitles.count, id: \.self) { idx in
                Button(action: { selectedTab = idx }) {
                    Text(segmentTitles[idx])
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedTab == idx ? .white : AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == idx ? AppColors.accent : AppColors.card)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }
    
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(AppColors.accent)
                    .scaleEffect(1.3)
                Spacer()
            } else if let error = viewModel.errorMessage {
                errorView(error: error)
            } else {
                if selectedTab == 0 {
                    receivedRecipesView
                } else {
                    sentRecipesView
                }
            }
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(AppColors.text)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var receivedRecipesView: some View {
        Group {
            if viewModel.receivedRecipes.isEmpty {
                Spacer()
                EmptyStateView(message: "No recipes have been sent to you yet.")
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        ForEach(viewModel.receivedRecipes) { recipe in
                            ReceivedRecipeCard(
                                recipe: recipe,
                                user: viewModel.userCache[recipe.fromUserId],
                                recipeDetail: viewModel.recipeCache[recipe.recipeId],
                                reaction: reactionTypeToString(recipe.reaction),
                                onTap: {
                                    if let detail = viewModel.recipeCache[recipe.recipeId] {
                                        selectedRecipe = detail
                                    }
                                },
                                onLongPress: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedRecipeForEmoji = recipe
                                    }
                                },
                                showEmojiMenu: false,
                                onEmojiSelect: { _ in },
                                hideEmojiOverlay: false
                            )
                            .task {
                                await viewModel.fetchUserIfNeeded(userId: recipe.fromUserId)
                                await viewModel.fetchRecipeIfNeeded(recipeId: recipe.recipeId)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }
    
    private var sentRecipesView: some View {
        Group {
            if viewModel.sentRecipes.isEmpty {
                Spacer()
                EmptyStateView(message: "You haven't sent any recipes yet.")
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        ForEach(viewModel.sentRecipes) { recipe in
                            SentRecipeCard(
                                recipe: recipe,
                                sender: viewModel.userCache[Auth.auth().currentUser?.uid ?? ""],
                                receiver: viewModel.userCache[recipe.toUserId],
                                recipeDetail: viewModel.recipeCache[recipe.recipeId],
                                onTap: {
                                    if let detail = viewModel.recipeCache[recipe.recipeId] {
                                        selectedRecipe = detail
                                    }
                                }
                            )
                            .task {
                                await viewModel.fetchUserIfNeeded(userId: recipe.toUserId)
                                await viewModel.fetchRecipeIfNeeded(recipeId: recipe.recipeId)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }
    
    @ViewBuilder
    private var emojiMenuOverlay: some View {
        if let selectedEmojiRecipe = selectedRecipeForEmoji {
            ZStack {
                // Blur background
                Color.black.opacity(0.3)
                    .blur(radius: 20)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedRecipeForEmoji = nil
                        }
                    }
                
                // Centered recipe card with emoji menu
                VStack(spacing: 20) {
                    // Re-render card but centered
                    ReceivedRecipeCard(
                        recipe: selectedEmojiRecipe,
                        user: viewModel.userCache[selectedEmojiRecipe.fromUserId],
                        recipeDetail: viewModel.recipeCache[selectedEmojiRecipe.recipeId],
                        reaction: reactionTypeToString(selectedEmojiRecipe.reaction),
                        onTap: {},
                        onLongPress: {},
                        showEmojiMenu: false,
                        onEmojiSelect: { _ in },
                        hideEmojiOverlay: true
                    )
                    .scaleEffect(0.9)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    
                    // Emoji menu
                    EmojiMenu { emoji in
                        Task {
                            await handleEmojiSelection(emoji: emoji, recipe: selectedEmojiRecipe)
                        }
                    }
                    .scaleEffect(1.0)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(1000)
        }
    }
    
    @ViewBuilder
    private var flyingEmojiView: some View {
        if let flyingEmoji = flyingEmoji {
            Text(flyingEmoji)
                .font(.system(size: 32))
                .position(flyingEmojiPosition)
                .zIndex(1001)
                .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var navigationLink: some View {
        NavigationLink(
            destination: selectedRecipe == nil ? nil : AnyView(RecipeDetailView(recipe: selectedRecipe!)),
            isActive: Binding(
                get: { selectedRecipe != nil },
                set: { if !$0 { selectedRecipe = nil } }
            )
        ) {
            EmptyView()
        }
        .hidden()
    }
    
    // MARK: - Helper Methods
    
    private func reactionTypeToString(_ reaction: ReactionType?) -> String? {
        return reaction?.rawValue
    }
    
    private func setupViewModel() {
        viewModel.router = router
        Task {
            await viewModel.loadReceivedRecipes()
            await viewModel.loadSentRecipes()
        }
    }
    
    private func handleEmojiSelection(emoji: String, recipe: ReceivedSharedRecipe) async {
        // Start flying emoji animation
        let emojiText = emojiText(for: emoji)
        flyingEmoji = emojiText
        // Starting position: below menu
        flyingEmojiPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 + 100)
        
        // Calculate emoji overlay position relative to photo
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Overlay card position on screen (relative to photo)
        let cardCenterX = screenWidth / 2
        let cardCenterY = screenHeight / 2 - 55 // card slightly above
        
        // Card left edge (with padding calculations)
        let cardScale: CGFloat = 0.9
        let approximateCardWidth: CGFloat = screenWidth * 0.85 * cardScale
        let cardLeftX = cardCenterX - (approximateCardWidth / 2)
        
        // Bubble height
        let cardHeight: CGFloat = 90 * cardScale
        let cardBottomY = cardCenterY + (cardHeight / 2)
        
        // Emoji overlay: from bubble's left edge with offset
        // Lower left corner relative to photo, slightly outside
        let emojiTargetX = cardLeftX + 6 // slightly inside from left edge
        let emojiTargetY = cardBottomY - 70 // higher from bottom edge (emoji overlay position)
        
        // Animate to target position
        withAnimation(.easeInOut(duration: 0.8)) {
            flyingEmojiPosition = CGPoint(x: emojiTargetX, y: emojiTargetY)
        }
        
        // Send reaction to firebase
        if let reactionType = ReactionType(rawValue: emoji) {
            await viewModel.reactToRecipe(receivedRecipeId: recipe.id, reaction: reactionType)
        }
        
        // Clean up after animation and exit blur
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            flyingEmoji = nil
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedRecipeForEmoji = nil
            }
        }
    }
    
    private func emojiText(for reaction: String) -> String {
        switch reaction {
        case "like": return "👍"
        case "neutral": return "😐"
        case "dislike": return "👎"
        default: return ""
        }
    }
} 