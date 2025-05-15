import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: recipe.image ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(height: 200)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.title)
                        .bold()
                    
                    HStack {
                        Label("\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) min", systemImage: "clock")
                        Spacer()
                        Label(recipe.difficulty ?? "", systemImage: "chart.bar")
                        Spacer()
                        Label("\(recipe.servings ?? 0) servings", systemImage: "person.2")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    
                    Text("Ingredients")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(recipe.ingredients ?? [], id: \.self) { ingredient in
                        Text("• \(ingredient)")
                    }
                    
                    Text("Instructions")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(recipe.instructions ?? [], id: \.self) { step in
                        Text(step)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
} 