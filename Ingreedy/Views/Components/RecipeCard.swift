import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: recipe.image ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(height: 150)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(recipe.cuisine ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Label("\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) min", systemImage: "clock")
                    Spacer()
                    Label(recipe.difficulty ?? "", systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 