import SwiftUI

struct ProfileFavoritesGridCard: View {
    let favoriteRecipes: [Recipe]
    let onRemoveFavorite: (Recipe) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("My Favorites")
                    .font(.title3.bold())
                    .foregroundColor(AppColors.primary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 16)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
                    ForEach(favoriteRecipes, id: \ .id) { recipe in
                        let isFavorite = true
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeGridCard(
                                recipe: recipe,
                                isFavorite: isFavorite,
                                onFavoriteToggle: {
                                    onRemoveFavorite(recipe)
                                }
                            )
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