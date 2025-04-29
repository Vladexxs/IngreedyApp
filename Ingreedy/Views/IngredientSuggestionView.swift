import SwiftUI

struct IngredientSuggestionView: View {
    @StateObject private var viewModel = IngredientSuggestionViewModel()
    
    var body: some View {
        NavigationView {
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
                    List(viewModel.suggestedRecipes) { recipe in
                        VStack(alignment: .leading) {
                            Text(recipe.name)
                                .font(.body)
                        }
                    }
                    .frame(height: 180)
                }
                
                if !viewModel.partialMatchRecipes.isEmpty {
                    Text("Kısmi Eşleşen Tarifler")
                        .font(.headline)
                        .padding(.top)
                    List(viewModel.partialMatchRecipes, id: \.recipe.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.recipe.name)
                                .font(.body)
                            if !item.missingIngredients.isEmpty {
                                Text("Eksik malzemeler: \(item.missingIngredients.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .frame(height: 180)
                }
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    IngredientSuggestionView()
} 