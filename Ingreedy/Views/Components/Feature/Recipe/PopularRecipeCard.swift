import SwiftUI
import Kingfisher

struct PopularRecipeCard: View {
    let recipe: Recipe
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                    HStack {
                        Spacer()
                        KFImage(url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 155, height: 112)
                            .clipped()
                            .cornerRadius(16)
                        Spacer()
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 8)
                } else {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.card)
                            .frame(width: 155, height: 112)
                        Spacer()
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 8)
                }
                Text(recipe.name)
                    .font(.subheadline.bold())
                    .foregroundColor(AppColors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.horizontal, 12)
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
                Spacer(minLength: 4)
            }
            .frame(width: 170, height: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(AppColors.card)
            .cornerRadius(22)
            .shadow(color: AppColors.primary.opacity(0.10), radius: 6, y: 3)
            Button(action: { onFavoriteToggle() }) {
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
} 