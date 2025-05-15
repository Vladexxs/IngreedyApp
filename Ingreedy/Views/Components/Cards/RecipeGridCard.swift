import SwiftUI

struct RecipeGridCard: View {
    let recipe: Recipe
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
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
            
            Button(action: { onFavoriteToggle() }) {
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