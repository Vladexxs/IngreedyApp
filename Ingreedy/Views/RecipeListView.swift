import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var searchText = ""
    @State private var selectedIngredients: Set<String> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header + SearchBar (sade, minimal)
                    VStack(spacing: 0) {
                        HStack {
                            Text("Recipes")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.text)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        SearchBar(text: $searchText, onSearch: {
                            viewModel.searchRecipes(query: searchText)
                        })
                        .padding(.horizontal, 16)
                        .padding(.bottom, 6)
                    }
                    .background(AppColors.background)
                    // Hiçbir gradient veya divider yok

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
                                ForEach(viewModel.recipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        RecipeGridCard(recipe: recipe)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchRecipes()
            }
        }
    }
}

struct RecipeGridCard: View {
    @State private var isFavorite = false
    let recipe: Recipe
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 170, height: 120)
                            .clipped()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AppColors.card)
                            .frame(width: 170, height: 120)
                    }
                    .cornerRadius(18)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(AppColors.card)
                        .frame(width: 170, height: 120)
                }
                
                Text(recipe.name)
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.text)
                    .lineLimit(2)
                    .frame(width: 160, alignment: .leading)
                
                Spacer()
                // Alt satır: süre ve zorluk, modern ve hizalı
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(AppColors.accent)
                        Text("\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) Min")
                            .font(.caption)
                            .foregroundColor(AppColors.text)
                    }
                    Spacer()
                    if let difficulty = recipe.difficulty, !difficulty.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar")
                                .font(.caption)
                                .foregroundColor(AppColors.accent)
                            Text(difficulty.capitalized)
                                .font(.caption)
                                .foregroundColor(AppColors.text)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 10)
            }
            .frame(width: 170, height: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(AppColors.card)
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            Button(action: { isFavorite.toggle() }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : AppColors.primary)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .offset(x: -10, y: 10)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.primary.opacity(0.6))
                    .font(.system(size: 18, weight: .medium))
                
                TextField("Search recipes...", text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.text)
                    .autocapitalization(.none)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.primary.opacity(0.6))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppColors.card.opacity(0.7))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            
            Button(action: onSearch) {
                Text("Search")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppColors.accent)
                    .cornerRadius(16)
                    .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: recipe.image ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
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
        .navigationBarTitleDisplayMode(.inline)
    }
} 