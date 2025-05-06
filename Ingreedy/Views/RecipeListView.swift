import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var searchText = ""
    @State private var selectedIngredients: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    SearchBar(text: $searchText, onSearch: {
                        viewModel.searchRecipes(query: searchText)
                    })
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .frame(maxHeight: .infinity)
                    } else {
                        List(viewModel.recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeRow(recipe: recipe)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .padding(.bottom, 120) // Extra padding for tab bar
                    }
                }
            }
            .navigationTitle("Recipes")
            .onAppear {
                viewModel.fetchRecipes()
            }
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: recipe.image ?? "")) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.cuisine ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("\((recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)) min • \(recipe.difficulty ?? "")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search recipes...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
            }
        }
        .padding()
    }
}

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