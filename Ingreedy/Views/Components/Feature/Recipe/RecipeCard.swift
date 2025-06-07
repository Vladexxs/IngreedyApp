import SwiftUI
import Kingfisher

struct RecipeCard: View {
    // MARK: - Properties
    let recipe: Recipe
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Recipe Image
            recipeImageView
            
            // Recipe Info
            recipeInfoView
        }
        .background(AppColors.card)
        .cornerRadius(12)
        .shadow(color: AppColors.shadow, radius: 4, y: 2)
    }
}

// MARK: - Private Views
private extension RecipeCard {
    
    var recipeImageView: some View {
        KFImage(URL(string: recipe.image ?? ""))
            .configureForRecipeImage()
            .placeholder {
                Rectangle()
                    .fill(AppColors.card)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.secondary)
                    )
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 150)
            .clipped()
    }
    
    var recipeInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Recipe Name
            Text(recipe.name)
                .font(.headline)
                .foregroundColor(AppColors.primary)
                .lineLimit(2)
            
            // Cuisine Type
            Text(recipe.cuisine ?? "International")
                .font(.subheadline)
                .foregroundColor(AppColors.secondary)
            
            // Recipe Stats
            recipeStatsView
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    var recipeStatsView: some View {
        HStack {
            Label(
                "\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) min", 
                systemImage: "clock"
            )
            
            Spacer()
            
            Label(
                recipe.difficulty ?? "Easy", 
                systemImage: "chart.bar"
            )
        }
        .font(.caption)
        .foregroundColor(AppColors.secondary)
    }
} 