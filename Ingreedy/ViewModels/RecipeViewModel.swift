import Foundation
import Combine

class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let recipeService = RecipeService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchRecipes() {
        isLoading = true
        recipeService.fetchRecipes { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let recipes):
                    self?.recipes = recipes
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func searchRecipes(query: String) {
        isLoading = true
        recipeService.searchRecipes(query: query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let recipes):
                    self?.recipes = recipes
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func filterRecipesByIngredients(ingredients: [String]) -> [Recipe] {
        return recipes.filter { recipe in
            ingredients.allSatisfy { ingredient in
                recipe.ingredients?.contains(ingredient) == true
            }
        }
    }
} 