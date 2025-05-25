import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct SharedRecipesView: View {
    @StateObject private var viewModel = SharedRecipesViewModel()
    @State private var selectedTab = 0
    @State private var showEmojiMenuFor: String? = nil // receivedRecipeId
    @State private var selectedRecipe: Recipe? = nil

    let segmentTitles = ["Bana Gönderilenler", "Benim Gönderdiklerim"]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 0) {
                // Başlık
                HStack {
                    Text("Paylaşılanlar")
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
                            EmptyStateView(message: "Sana henüz tarif gönderilmedi.")
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
                            EmptyStateView(message: "Henüz kimseye tarif göndermedin.")
                            Spacer()
                        } else {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 18) {
                                    ForEach(viewModel.sentRecipes) { recipe in
                                        SentRecipeCard(
                                            recipe: recipe,
                                            user: viewModel.userCache[Auth.auth().currentUser?.uid ?? ""],
                                            recipeDetail: viewModel.recipeCache[recipe.recipeId]
                                        )
                                        .task {
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
            ZStack(alignment: .bottomLeading) {
                ZStack(alignment: .center) {
                    BubbleWithTailRight()
                        .fill(AppColors.card)
                        .shadow(color: AppColors.shadow, radius: 4, y: 1)
                    VStack(spacing: 0) {
                        if let recipeDetail = recipeDetail {
                            if let imageUrl = recipeDetail.image, let url = URL(string: imageUrl), !imageUrl.isEmpty {
                                KFImage(URL(string: imageUrl))
                                    .placeholder {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(AppColors.card)
                                    }
                                    .onFailure { error in
                                        print("[DEBUG] Kingfisher yükleme hatası: \(error.localizedDescription) - URL: \(imageUrl)")
                                    }
                                    .onSuccess { result in
                                        print("[DEBUG] Kingfisher yükleme başarılı: \(imageUrl)")
                                    }
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .shadow(color: AppColors.accent.opacity(0.18), radius: 6, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColors.card)
                                    .frame(width: 100, height: 70)
                            }
                            Text(recipeDetail.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.primary)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                                .padding(.horizontal, 6)
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppColors.card)
                                .frame(width: 100, height: 70)
                            Text("Yükleniyor...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.secondary)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                }
                .frame(height: 120)
                // Emoji overlay (reaction) - far bottom left, outside bubble
                if let reaction = reaction, !showEmojiMenu {
                    // Emoji için ReceivedRecipeCard'a uygun offset değerleri
                    emojiOverlay(for: reaction, offsetX: -18, offsetY: 18)
                }
                // Emoji menu
                if showEmojiMenu {
                    EmojiMenu { emoji in
                        onEmojiSelect(emoji)
                    }
                    .offset(x: -8, y: -54)
                    .zIndex(3)
                }
            }
            // Profil fotoğrafı (gönderen)
            if let user = user {
                if let urlString = user.profileImageUrl, !urlString.isEmpty {
                    KFImage(URL(string: urlString))
                        .placeholder {
                            Circle()
                                .fill(AppColors.primary.opacity(0.2))
                                .overlay(ProgressView())
                        }
                        .onFailure { error in
                            print("[DEBUG] Kingfisher yükleme hatası: \(error.localizedDescription) - URL: \(urlString)")
                        }
                        .onSuccess { result in
                            print("[DEBUG] Kingfisher yükleme başarılı: \(urlString)")
                        }
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
                        .onAppear { print("[DEBUG] Profil resmi URL'si geçersiz veya boş - Kullanıcı: \(user.fullName)") }
                }
            } else {
                Circle().fill(AppColors.primary.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay(ProgressView())
                    .onAppear { print("[DEBUG] Kullanıcı nesnesi nil") }
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
    let user: User?
    let recipeDetail: Recipe?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Profil fotoğrafı
            if let user = user {
                if let urlString = user.profileImageUrl, !urlString.isEmpty {
                    KFImage(URL(string: urlString))
                        .placeholder {
                            Circle()
                                .fill(AppColors.primary.opacity(0.2))
                                .overlay(ProgressView())
                        }
                        .onFailure { error in
                            print("[DEBUG] SentRecipeCard - Kingfisher yükleme hatası: \(error.localizedDescription) - URL: \(urlString)")
                        }
                        .onSuccess { result in
                            print("[DEBUG] SentRecipeCard - Kingfisher yükleme başarılı: \(urlString)")
                        }
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
                        .onAppear { print("[DEBUG] SentRecipeCard - Profil resmi URL'si geçersiz veya boş - Kullanıcı: \(user.fullName)") }
                }
            } else {
                Circle().fill(AppColors.primary.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay(ProgressView())
                    .onAppear { print("[DEBUG] SentRecipeCard - Kullanıcı nesnesi nil") }
            }
            
            ZStack(alignment: .center) {
                BubbleWithTail()
                    .fill(AppColors.card)
                    .shadow(color: AppColors.shadow, radius: 4, y: 1)
                VStack(spacing: 0) {
                    if let recipeDetail = recipeDetail {
                        if let imageUrl = recipeDetail.image, !imageUrl.isEmpty {
                            KFImage(URL(string: imageUrl))
                                .placeholder {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppColors.card)
                                }
                                .onFailure { error in
                                    print("[DEBUG] Kingfisher yükleme hatası: \(error.localizedDescription) - URL: \(imageUrl)")
                                }
                                .onSuccess { result in
                                    print("[DEBUG] Kingfisher yükleme başarılı: \(imageUrl)")
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: AppColors.accent.opacity(0.18), radius: 6, y: 2)
                        } else {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppColors.card)
                                .frame(width: 100, height: 70)
                        }
                        Text(recipeDetail.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primary)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 6)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppColors.card)
                            .frame(width: 100, height: 70)
                        Text("Yükleniyor...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
            }
            .frame(height: 120) // Keep frame for ZStack
            // Emoji overlay (reaction) - positioned relative to the bubble
            if let reaction = recipe.reaction {
                // Emoji için SentRecipeCard'a uygun offset değerleri
                // Baloncuğun sağ alt köşesine ve dışına konumlandırmak için offsetler
                emojiOverlay(for: reaction, offsetX: -30, offsetY: 50) // Offset değerlerini ayarlayacağız
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .padding(.trailing, 24) // Add trailing padding for right tail
        .onAppear {
            print("[DEBUG] SentRecipeCard - Kullanıcı bilgileri:")
            print("- Kullanıcı: \(user?.fullName ?? "nil")")
            print("- Profil URL: \(user?.profileImageUrl ?? "nil")")
            print("- Tepki: \(recipe.reaction ?? "Yok")")
        }
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
