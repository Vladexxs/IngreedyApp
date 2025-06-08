import SwiftUI
import Kingfisher

struct PopularRecipeCard: View {
    // MARK: - Properties
    let recipe: Recipe
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            recipeCardContent
            favoriteButton
        }
    }
}

// MARK: - Private Views
private extension PopularRecipeCard {
    
    var recipeCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeImageView
            recipeNameView
            recipeCaloriesView
            Spacer(minLength: 4)
        }
        .frame(width: 170, height: 200)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(AppColors.card)
        .cornerRadius(22)
        .shadow(color: AppColors.primary.opacity(0.10), radius: 6, y: 3)
    }
    
    var recipeImageView: some View {
        HStack {
            Spacer()
            
            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                            KFImage(url)
                .configureForRecipeImage(size: CGSize(width: 250, height: 180))
                    .placeholder {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.secondary.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(AppColors.secondary)
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 155, height: 112)
                    .clipped()
                    .cornerRadius(16)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.secondary.opacity(0.3))
                    .frame(width: 155, height: 112)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.secondary)
                    )
            }
            
            Spacer()
        }
        .padding(.top, 14)
        .padding(.horizontal, 8)
    }
    
    var recipeNameView: some View {
        Text(recipe.name)
            .font(.subheadline.bold())
            .foregroundColor(AppColors.text)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.horizontal, 12)
    }
    
    var recipeCaloriesView: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame")
                .font(.caption)
                .foregroundColor(AppColors.accent)
            
            Text("\(recipe.caloriesPerServing ?? 0) Kcal")
                .font(.caption)
                .foregroundColor(AppColors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }
    
    var favoriteButton: some View {
        Button(action: onFavoriteToggle) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red : AppColors.primary)
                .padding(8)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 2, y: 1)
        }
        .offset(x: -10, y: 10)
    }
} 