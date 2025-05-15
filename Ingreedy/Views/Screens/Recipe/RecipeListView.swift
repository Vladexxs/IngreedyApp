import SwiftUI
import FirebaseAuth

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var searchText = ""
    @State private var selectedIngredients: Set<String> = []
    
    var body: some View {
        let userId = Auth.auth().currentUser?.uid ?? ""
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
                                    let isFavorite = viewModel.userFavorites.contains(recipe.id)
                                    RecipeGridCard(
                                        recipe: recipe,
                                        isFavorite: isFavorite,
                                        onFavoriteToggle: {
                                            if isFavorite {
                                                viewModel.removeRecipeFromFavorites(recipeId: recipe.id)
                                            } else {
                                                viewModel.addRecipeToFavorites(recipeId: recipe.id)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.userId = userId
                viewModel.fetchRecipes()
                viewModel.fetchUserFavorites()
            }
        }
    }
}

// RecipeGridCard ve RecipeDetailView component tanımları kaldırıldı. Eğer kullanıyorsan, import etmeyi unutma. 