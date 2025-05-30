import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var showShareSheet = false
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = RecipeViewModel()
    @State private var isFavorite = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Image + Custom Back & Favorite Button
                    ZStack(alignment: .top) {
                        KFImage(URL(string: recipe.image ?? ""))
                            .resizable()
                            .scaledToFill()
                            .frame(height: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.45)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            )
                            .ignoresSafeArea(.all, edges: .top)
                        HStack {
                            // Back Button
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            Spacer()
                            // Favorite Button
                            Button(action: {
                                if isFavorite {
                                    viewModel.removeRecipeFromFavorites(recipeId: recipe.id)
                                } else {
                                    viewModel.addRecipeToFavorites(recipeId: recipe.id)
                                }
                            }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(isFavorite ? .red : .white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                    }
                    .frame(height: 400)
                    .padding(.bottom, -48)
                    .padding(.top, -8)
                    // Info Card (arka planı beyaz, gölgelendirme mevcut)
                    VStack(spacing: 12) {
                        Text(recipe.name)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppColors.primary)
                            .multilineTextAlignment(.center)
                        if let count = recipe.ingredients?.count {
                            Text("\(count) ingredients")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondary)
                        }
                        HStack(spacing: 24) {
                            InfoItem(icon: "clock", text: "\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) min")
                            if let calories = recipe.caloriesPerServing {
                                InfoItem(icon: "flame", text: "\(calories) Kcal")
                            }
                            if let servings = recipe.servings {
                                InfoItem(icon: "person.2", text: "\(servings) serve")
                            }
                            if let diff = recipe.difficulty, !diff.isEmpty {
                                InfoItem(icon: "chart.bar", text: diff.capitalized)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 24)
                    .background(Color.white)
                    .cornerRadius(26)
                    .shadow(color: AppColors.shadow, radius: 10, y: 3)
                    .padding(.horizontal, 24)
                    .offset(y: -24)
                    .padding(.bottom, 24)

                    // Ingredients Card (daha aşağıda, spacing artırıldı)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                        ForEach(recipe.ingredients ?? [], id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                    .foregroundColor(AppColors.accent)
                                Text(ingredient)
                                    .font(.body)
                                    .foregroundColor(AppColors.text)
                            }
                        }
                    }
                    .padding(36)
                    .background(AppColors.card)
                    .cornerRadius(26)
                    .shadow(color: AppColors.shadow, radius: 10, y: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 0)

                    // Instructions Card (spacing ve padding artırıldı)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Cooking instruction")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                        ForEach(Array((recipe.instructions ?? []).enumerated()), id: \.element) { idx, step in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.accent)
                                        .frame(width: 28, height: 28)
                                    Text("\(idx + 1)")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                Text(step)
                                    .font(.body)
                                    .foregroundColor(AppColors.text)
                                    .padding(.top, 2)
                            }
                            .padding(14)
                            .background(AppColors.card.opacity(0.8))
                            .cornerRadius(16)
                        }
                    }
                    .padding(24)
                    .background(AppColors.card)
                    .cornerRadius(26)
                    .shadow(color: AppColors.shadow, radius: 10, y: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
            // Share Button (ekranın en altında, içerikten bağımsız)
            HStack {
                Spacer()
                Button(action: { showShareSheet = true }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Share")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 20)
                    .background(AppColors.accent)
                    .cornerRadius(22)
                    .shadow(color: AppColors.accent.opacity(0.18), radius: 8, y: 2)
                }
                Spacer()
            }
            .padding(.bottom, 32)
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showShareSheet) {
            UserSelectionSheet(recipeId: recipe.id)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let user = Auth.auth().currentUser {
                viewModel.userId = user.uid
                viewModel.fetchUserFavorites()
            }
        }
        .onReceive(viewModel.$userFavorites) { favorites in
            isFavorite = favorites.contains(recipe.id)
        }
    }
}

struct InfoItem: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(AppColors.accent)
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppColors.text)
        }
    }
}

// Kullanıcı seçimi ve paylaşım için sheet
struct UserSelectionSheet: View {
    let recipeId: Int
    @Environment(\.dismiss) var dismiss
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List(users) { user in
                Button {
                    Task {
                        await sendRecipe(toUserId: user.id)
                        dismiss()
                    }
                } label: {
                    HStack {
                        if let url = user.profileImageUrl, !url.isEmpty {
                            AsyncImage(url: URL(string: url)) { image in
                                image.resizable()
                            } placeholder: {
                                Circle().fill(Color.gray)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 40, height: 40)
                                .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                        }
                        Text(user.fullName)
                    }
                }
            }
            .navigationTitle("Kime göndermek istiyorsun?")
            .onAppear { loadUsers() }
            .overlay {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if let error = errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
        }
    }

    func loadUsers() {
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
            users = snapshot?.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                if id == currentUserId { return nil }
                let fullName = data["fullName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                return User(id: id, email: email, fullName: fullName, favorites: [], friends: nil, profileImageUrl: profileImageUrl, createdAt: nil)
            } ?? []
        }
    }

    func sendRecipe(toUserId: String) async {
        let service = SharedRecipeService()
        do {
            try await service.sendRecipe(toUserId: toUserId, recipeId: recipeId)
        } catch {
            // Hata yönetimi (isteğe bağlı)
        }
    }
} 
