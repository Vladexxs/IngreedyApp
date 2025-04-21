import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
            // Placeholder image
            Rectangle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.primary)
                )
                .cornerRadius(AppConstants.CornerRadius.medium)
            
            Text(recipe.title)
                .font(.system(size: AppConstants.FontSize.headline))
                .foregroundColor(AppColors.text)
                .lineLimit(2)
            
            HStack {
                Label(recipe.cookingTime, systemImage: "clock")
                    .font(.system(size: AppConstants.FontSize.body))
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Label(recipe.difficulty, systemImage: "chart.bar.fill")
                    .font(.system(size: AppConstants.FontSize.body))
                    .foregroundColor(AppColors.text)
            }
        }
        .padding()
        .background(AppColors.primary.opacity(0.1))
        .cornerRadius(AppConstants.CornerRadius.medium)
    }
} 