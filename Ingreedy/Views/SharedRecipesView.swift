import SwiftUI

struct SharedRecipesView: View {
    @StateObject private var viewModel = SharedRecipesViewModel()
    @State private var selectedTab = 0
    @State private var showEmojiMenuFor: String? = nil // receivedRecipeId

    let segmentTitles = ["Bana Gönderilenler", "Benim Gönderdiklerim"]

    var body: some View {
        NavigationView {
            VStack {
                Text("Paylaşılanlar")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("MainOrange"))
                    .padding(.top, 16)

                Picker("", selection: $selectedTab) {
                    ForEach(0..<segmentTitles.count, id: \.self) { idx in
                        Text(segmentTitles[idx])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    if selectedTab == 0 {
                        // Bana Gönderilenler
                        List(viewModel.receivedRecipes) { recipe in
                            ReceivedRecipeCard(
                                recipe: recipe,
                                onTap: { /* Detay sayfasına geçiş */ },
                                onLongPress: { showEmojiMenuFor = recipe.id }
                            )
                            .listRowSeparator(.hidden)
                            .background(
                                Group {
                                    if showEmojiMenuFor == recipe.id {
                                        EmojiMenu { emoji in
                                            Task {
                                                await viewModel.reactToRecipe(receivedRecipeId: recipe.id, reaction: emoji)
                                                showEmojiMenuFor = nil
                                            }
                                        }
                                    }
                                }
                            )
                        }
                        .listStyle(PlainListStyle())
                    } else {
                        // Benim Gönderdiklerim
                        List(viewModel.sentRecipes) { recipe in
                            SentRecipeCard(recipe: recipe)
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .background(Color("Background").ignoresSafeArea())
            .onAppear {
                Task {
                    await viewModel.loadReceivedRecipes()
                    await viewModel.loadSentRecipes()
                }
            }
        }
    }
}

// MARK: - Kartlar

struct ReceivedRecipeCard: View {
    let recipe: ReceivedSharedRecipe
    var onTap: () -> Void
    var onLongPress: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Profil resmi (dummy)
            Circle()
                .fill(Color("MainBrown"))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                )

            // Tarif önizlemesi (dummy)
            VStack(alignment: .leading, spacing: 4) {
                Text("Tarif #\(recipe.recipeId)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Gönderen: \(recipe.fromUserId)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let reaction = recipe.reaction {
                    Text("Tepkiniz: \(emojiText(for: reaction))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color("MainOrange").opacity(0.08), radius: 4, x: 0, y: 2)
        .onTapGesture { onTap() }
        .onLongPressGesture { onLongPress() }
    }

    func emojiText(for reaction: String) -> String {
        switch reaction {
        case "like": return "👍"
        case "neutral": return "😐"
        case "dislike": return "👎"
        default: return ""
        }
    }
}

struct SentRecipeCard: View {
    let recipe: SentSharedRecipe

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color("MainOrange"))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("Tarif #\(recipe.recipeId)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Alıcı: \(recipe.toUserId)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color("MainOrange").opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Emoji Menü

struct EmojiMenu: View {
    var onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 24) {
            Button { onSelect("like") } label: { Text("👍").font(.largeTitle) }
            Button { onSelect("neutral") } label: { Text("😐").font(.largeTitle) }
            Button { onSelect("dislike") } label: { Text("👎").font(.largeTitle) }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 8)
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