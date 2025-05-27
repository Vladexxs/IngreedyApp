import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct SharedRecipesView: View {
    @StateObject private var viewModel = SharedRecipesViewModel()
    @State private var selectedTab = 0
    @State private var showEmojiMenuFor: String? = nil // receivedRecipeId
    @State private var selectedRecipe: Recipe? = nil

    let segmentTitles = ["Received", "Sent"]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Başlık
                HStack {
                    Text("Shared Recipes")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.primary)
                    Spacer()
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                // Simetrik Segment
                HStack(spacing: 0) {
                    ForEach(Array(segmentTitles.enumerated()), id: \.offset) { (idx, title) in
                        Button(action: { selectedTab = idx }) {
                            Text(title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTab == idx ? .white : AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedTab == idx ? AppColors.accent : AppColors.card)
                        }
                        .cornerRadius(idx == 0 ? 18 : 0, corners: [.topLeft, .bottomLeft])
                        .cornerRadius(idx == segmentTitles.count - 1 ? 18 : 0, corners: [.topRight, .bottomRight])
                    }
                }
                .frame(maxWidth: .infinity)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 8)
                // İçerik
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.accent)
                        .scaleEffect(1.3)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(AppColors.text)
                            .font(.system(size: 16, weight: .medium))
                    }
                    Spacer()
                } else {
                    if selectedTab == 0 {
                        // Bana Gönderilenler
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
                                            reaction: recipe.reaction,
                                            onTap: {
                                                if let detail = viewModel.recipeCache[recipe.recipeId] {
                                                    selectedRecipe = detail
                                                }
                                            },
                                            onLongPress: { showEmojiMenuFor = recipe.id },
                                            showEmojiMenu: showEmojiMenuFor == recipe.id,
                                            onEmojiSelect: { emoji in
                                                Task {
                                                    await viewModel.reactToRecipe(receivedRecipeId: recipe.id, reaction: emoji)
                                                    showEmojiMenuFor = nil
                                                }
                                            }
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
                    } else {
                        // Benim Gönderdiklerim
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
                                            recipeDetail: viewModel.recipeCache[recipe.recipeId]
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
            }
            .onTapGesture { showEmojiMenuFor = nil } // Emoji menüsünü kapatmak için
            .onAppear {
                Task {
                    await viewModel.loadReceivedRecipes()
                    await viewModel.loadSentRecipes()
                }
            }
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
    }
}

// MARK: - Kartlar

struct ReceivedRecipeCard: View {
    let recipe: ReceivedSharedRecipe
    let user: User?
    let recipeDetail: Recipe?
    var reaction: String?
    var onTap: () -> Void
    var onLongPress: () -> Void
    var showEmojiMenu: Bool
    var onEmojiSelect: (String) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Spacer(minLength: 0)
            ZStack(alignment: .bottomLeading) {
                BubbleWithTailRight()
                    .fill(AppColors.card)
                    .shadow(color: AppColors.shadow, radius: 4, y: 1)
                HStack(alignment: .center, spacing: 16) {
                    // En solda: Sadece isim ve altında 'Gönderildi' badge'i
                    if let user = user {
                        VStack(spacing: 2) {
                            Text(user.fullName)
                                .font(.caption)
                                .foregroundColor(AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text("by")
                                .font(.caption2)
                                .foregroundColor(AppColors.primary)
                            Text("Sent")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.accent)
                                .cornerRadius(10)
                        }
                        .frame(minWidth: 60, alignment: .center)
                    }
                    // Ortada: Yemek adı
                    Text(recipeDetail?.name ?? "Loading...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    // En sağda: Yemek resmi
                    if let imageUrl = recipeDetail?.image, !imageUrl.isEmpty {
                        KFImage(URL(string: imageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.trailing, 8)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(height: 90, alignment: .center)
                // Emoji overlay sol alt köşe
                if let reaction = reaction, !showEmojiMenu {
                    emojiOverlay(for: reaction, offsetX: -18, offsetY: 18)
                }
                if showEmojiMenu {
                    EmojiMenu { emoji in
                        onEmojiSelect(emoji)
                    }
                    .offset(x: -8, y: -54)
                    .zIndex(3)
                }
            }
            .frame(height: 90)
            // Profil fotoğrafı en sağda (balonun dışında)
            if let user = user {
                if let urlString = user.profileImageUrl, !urlString.isEmpty {
                    KFImage(URL(string: urlString))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                } else {
                    Circle().fill(AppColors.primary.opacity(0.2))
                        .overlay(Text(user.fullName.prefix(1)).font(.caption).foregroundColor(AppColors.primary))
                        .frame(width: 48, height: 48)
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                }
            } else {
                Circle().fill(AppColors.primary.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay(ProgressView())
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .padding(.leading, 24)
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
    }

    func emojiText(for reaction: String) -> String {
        switch reaction {
        case "like": return "👍"
        case "neutral": return "😐"
        case "dislike": return "👎"
        default: return ""
        }
    }

    @ViewBuilder
    private func emojiOverlay(for reaction: String, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        Text(emojiText(for: reaction))
            .font(.system(size: 20))
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.15), radius: 4, y: 1)
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .offset(x: offsetX, y: offsetY) // Offset'i dışarıdan al
            .zIndex(2)
    }
}

struct BubbleWithTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tailWidth: CGFloat = 14
        let tailHeight: CGFloat = 18
        let cornerRadius: CGFloat = 20
        // Main bubble
        path.addRoundedRect(in: CGRect(x: tailWidth, y: 0, width: rect.width - tailWidth, height: rect.height), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        // Tail (left middle)
        path.move(to: CGPoint(x: tailWidth, y: rect.midY - tailHeight/2))
        path.addLine(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: tailWidth, y: rect.midY + tailHeight/2))
        path.closeSubpath()
        return path
    }
}

struct BubbleWithTailRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tailWidth: CGFloat = 14
        let tailHeight: CGFloat = 18
        let cornerRadius: CGFloat = 20
        // Main bubble
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width - tailWidth, height: rect.height), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        // Tail (right middle)
        path.move(to: CGPoint(x: rect.width - tailWidth, y: rect.midY - tailHeight/2))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width - tailWidth, y: rect.midY + tailHeight/2))
        path.closeSubpath()
        return path
    }
}

struct SentRecipeCard: View {
    let recipe: SentSharedRecipe
    let sender: User?      // Gönderen (her zaman sen)
    let receiver: User?    // Alıcı (tarifi gönderdiğin kişi)
    let recipeDetail: Recipe?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Gönderen profil fotoğrafı (her zaman en solda)
            if let sender = sender {
                if let urlString = sender.profileImageUrl, !urlString.isEmpty {
                    KFImage(URL(string: urlString))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                } else {
                    Circle().fill(AppColors.primary.opacity(0.2))
                        .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                        .frame(width: 48, height: 48)
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                }
            } else {
                Circle().fill(AppColors.primary.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay(ProgressView())
            }
            
            // Baloncuk
            ZStack(alignment: .bottomTrailing) {
                BubbleWithTail()
                    .fill(AppColors.card)
                    .shadow(color: AppColors.shadow, radius: 4, y: 1)
                
                // Baloncuk içeriği
                HStack(alignment: .center, spacing: 16) {
                    // En solda: Yemek resmi
                    if let imageUrl = recipeDetail?.image, !imageUrl.isEmpty {
                        KFImage(URL(string: imageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.leading, 8)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .padding(.leading, 8)
                    }
                    // Ortada: Yemek adı
                    Text(recipeDetail?.name ?? "Loading...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 8)
                    // En sağda: Alıcı avatarı + isim + badge
                    if let receiver = receiver {
                        VStack(spacing: 4) {
                            if let url = receiver.profileImageUrl, !url.isEmpty {
                                KFImage(URL(string: url))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                    .overlay(Text(receiver.fullName.prefix(1)).font(.caption).foregroundColor(AppColors.primary))
                            }
                            Text(receiver.fullName)
                                .font(.caption)
                                .foregroundColor(AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text("Sent")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.accent)
                                .cornerRadius(10)
                        }
                        .frame(minWidth: 60, alignment: .center)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(height: 90, alignment: .center)
                
                // Emoji overlay
                if let reaction = recipe.reaction {
                    emojiOverlay(for: reaction, offsetX: 18, offsetY: 18)
                }
            }
            .frame(height: 90)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .padding(.trailing, 24)
    }
    
    func emojiText(for reaction: String) -> String {
        switch reaction {
        case "like": return "👍"
        case "neutral": return "😐"
        case "dislike": return "👎"
        default: return ""
        }
    }

    @ViewBuilder
    private func emojiOverlay(for reaction: String, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        Text(emojiText(for: reaction))
            .font(.system(size: 20))
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.15), radius: 4, y: 1)
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .offset(x: offsetX, y: offsetY)
            .zIndex(2)
    }
}

// MARK: - Emoji Menü

struct EmojiMenu: View {
    var onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 24) {
            Button { onSelect("like") } label: { Text("👍").font(.system(size: 32)) }
            Button { onSelect("neutral") } label: { Text("😐").font(.system(size: 32)) }
            Button { onSelect("dislike") } label: { Text("👎").font(.system(size: 32)) }
        }
        .padding(16)
        .background(AppColors.card)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 8)
    }
}

// MARK: - Boş Durum

struct EmptyStateView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(AppColors.secondary)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
    }
}

// MARK: - Renkler (Assets.xcassets dosyanıza ekleyin)
// MainOrange: #FF9800
// MainBrown: #8D5524
// Background: #FFF8F0

// MARK: - Notlar
// - Profil resmi ve tarif önizlemesi için gerçek veriler DummyJSON ve Firestore'dan çekilerek entegre edilebilir.
// - Detay sayfasına geçiş için NavigationLink veya sheet kullanılabilir.
// - Renkleri Assets.xcassets dosyanıza eklemeyi unutmayın.

// ViewModel'e ek: Kullanıcı ve tarif görselleri için cache
// @MainActor
// class SharedRecipesViewModel: ObservableObject { ... }
// Helper: Köşe yuvarlama
// extension View { ... }
// struct RoundedCorner: Shape { ... } 
