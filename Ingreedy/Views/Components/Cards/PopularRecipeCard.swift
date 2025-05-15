import SwiftUI

struct PopularRecipeCard: View {
    @State private var isFavorite = false
    let recipe: Recipe
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
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
                HStack(spacing: 8) {
                    Image(systemName: "flame")
                        .font(.caption)
                        .foregroundColor(AppColors.accent)
                    Text("\(recipe.caloriesPerServing ?? 0) Kcal")
                        .font(.caption)
                        .foregroundColor(AppColors.text)
                }
                Spacer(minLength: 4)
            }
            .frame(width: 170, height: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(AppColors.card)
            .cornerRadius(22)
            .shadow(color: AppColors.primary.opacity(0.10), radius: 6, y: 3)
            Button(action: { isFavorite.toggle() }) {
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