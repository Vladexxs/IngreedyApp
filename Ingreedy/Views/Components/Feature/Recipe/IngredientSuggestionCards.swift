import SwiftUI
import Kingfisher

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(AppColors.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(AppColors.card)
        .cornerRadius(12)
        .shadow(color: AppColors.shadow, radius: 4, y: 2)
    }
}

// MARK: - Enhanced Recipe Card
struct EnhancedRecipeCard: View {
    let recipe: Recipe
    let matchType: MatchType
    
    enum MatchType {
        case perfect
        case partial
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                KFImage(URL(string: recipe.image ?? ""))
                    .configureForRecipeImage()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                
                // Match indicator
                Image(systemName: matchType == .perfect ? "checkmark.seal.fill" : "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(matchType == .perfect ? .green : AppColors.accent)
                            .frame(width: 28, height: 28)
                    )
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.primary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(AppColors.accent)
                    
                    Text("\(recipe.totalTime) min")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                    
                    Spacer()
                    
                    if let rating = recipe.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(AppColors.secondary)
                        }
                    }
                }
                
                if let calories = recipe.caloriesPerServing {
                    Text("\(calories) kcal")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.accent.opacity(0.8))
                        .cornerRadius(4)
                }
            }
            .padding(12)
        }
        .background(AppColors.card)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 6, y: 3)
    }
}

// MARK: - Partial Match Card
struct PartialMatchCard: View {
    let partialMatch: PartialMatchResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe Image
                                KFImage(URL(string: partialMatch.recipe.image ?? ""))
                        .configureForRecipeImage()
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(partialMatch.recipe.name)
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(partialMatch.matchPercentage)%")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Circle()
                                .fill(partialMatch.matchPercentage > 70 ? .green : partialMatch.matchPercentage > 40 ? AppColors.accent : .orange)
                        )
                }
                
                // Matching ingredients
                if !partialMatch.matchingIngredients.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(partialMatch.matchingIngredients.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                }
                
                // Missing ingredients
                if !partialMatch.missingIngredients.isEmpty {
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("+" + "\(partialMatch.missingIngredients.count) missing ingredients")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(AppColors.card)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow, radius: 4, y: 2)
    }
}

// MARK: - Ingredient Category Button
struct IngredientCategoryButton: View {
    let category: IngredientCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(category.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.subheadline.bold())
                        .foregroundColor(AppColors.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(category.ingredients.count) ingredients")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
            }
            .padding(16)
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(AppColors.card)
            .cornerRadius(16)
            .shadow(color: AppColors.shadow, radius: 4, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 