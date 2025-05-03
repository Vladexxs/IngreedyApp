import SwiftUI

struct IngredientSuggestionView: View {
    @StateObject private var viewModel = IngredientSuggestionViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Malzeme ile Tarif Öner")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    // Search bar for ingredient entry with add button
                    HStack {
                        TextField("Malzeme ara...", text: $viewModel.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                        Button(action: {
                            viewModel.addIngredient(viewModel.searchText)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .disabled(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Dynamic suggestion list
                    if !viewModel.ingredientSuggestions.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.ingredientSuggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        viewModel.addIngredient(suggestion)
                                    }) {
                                        HStack {
                                            Text(suggestion)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Image(systemName: "plus")
                                                .foregroundColor(.green)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // User's selected ingredients
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.userIngredients, id: \.self) { ingredient in
                                HStack(spacing: 4) {
                                    Text(ingredient)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(16)
                                    Button(action: {
                                        viewModel.removeIngredient(ingredient)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        viewModel.suggestRecipes()
                    }) {
                        HStack {
                            Image(systemName: "lightbulb")
                            Text("Tarifleri Öner")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.vertical)
                    .disabled(viewModel.userIngredients.isEmpty)
                    
                    if viewModel.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                    if let error = viewModel.error {
                        Text("Hata: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                    
                    if !viewModel.suggestedRecipes.isEmpty {
                        Text("Tam Eşleşen Tarifler")
                            .font(.headline)
                            .padding(.top)
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.suggestedRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeCard(recipe: recipe)
                                }
                            }
                        }
                    }
                    
                    if !viewModel.partialMatchRecipes.isEmpty {
                        Text("Kısmi Eşleşen Tarifler")
                            .font(.headline)
                            .padding(.top)
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.partialMatchRecipes, id: \.recipe.id) { item in
                                NavigationLink(destination: RecipeDetailView(recipe: item.recipe)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 12) {
                                            AsyncImage(url: URL(string: item.recipe.image ?? "")) { image in
                                                image.resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Color.gray
                                            }
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.recipe.name)
                                                    .font(.headline)
                                                if !item.matchingIngredients.isEmpty {
                                                    Text("Eşleşen malzemeler: \(item.matchingIngredients.joined(separator: ", "))")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                }
                                                if !item.missingIngredients.isEmpty {
                                                    Text("Eksik malzemeler: \(item.missingIngredients.joined(separator: ", "))")
                                                        .font(.caption)
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(radius: 2)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    IngredientSuggestionView()
} 