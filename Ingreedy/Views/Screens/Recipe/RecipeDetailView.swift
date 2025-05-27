import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var showShareSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    KFImage(URL(string: recipe.image ?? ""))
                        .resizable()
                        .frame(height: 200)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.title)
                            .bold()
                        
                        HStack {
                            Label("\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) min", systemImage: "clock")
                            Spacer()
                            Label(recipe.difficulty ?? "", systemImage: "chart.bar")
                            Spacer()
                            Label("\(recipe.servings ?? 0) servings", systemImage: "person.2")
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        
                        Text("Ingredients")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(recipe.ingredients ?? [], id: \.self) { ingredient in
                            Text("• \(ingredient)")
                        }
                        
                        Text("Instructions")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(recipe.instructions ?? [], id: \.self) { step in
                            Text(step)
                        }
                    }
                    .padding()
                }
            }
            // Alt Paylaş Butonu
            VStack {
                Spacer()
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Paylaş")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("MainOrange"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            UserSelectionSheet(recipeId: recipe.id)
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