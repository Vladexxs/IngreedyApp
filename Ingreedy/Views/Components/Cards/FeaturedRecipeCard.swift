import SwiftUI
import Kingfisher

struct FeaturedRecipeCard: View {
    let recipe: Recipe
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 230, height: 130)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.black.opacity(0.28))
                    )
                    .cornerRadius(22)
                    .shadow(color: AppColors.primary.opacity(0.10), radius: 8, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 22)
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 230, height: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.black.opacity(0.28))
                    )
                    .cornerRadius(22)
                    .shadow(color: AppColors.primary.opacity(0.10), radius: 8, y: 4)
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Featured")
                        .font(.caption2.bold())
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(AppColors.accent.opacity(0.12))
                        .cornerRadius(8)
                    Spacer()
                }
                Text(recipe.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text(recipe.cuisine ?? "")
                        .font(.caption)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) Min")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
        }
        .frame(width: 230, height: 130)
    }
} 