import Foundation
import Combine

class RecipeViewModel: BaseViewModel {
    @Published var recipes: [Recipe] = []
    private let recipeService = RecipeService()
    
    func fetchRecipes() {
        performNetwork({ completion in
            self.recipeService.fetchRecipes(completion: completion)
        }, onSuccess: { [weak self] recipes in
            self?.recipes = recipes
        })
    }
    
    func searchRecipes(query: String) {
        performNetwork({ completion in
            self.recipeService.searchRecipes(query: query, completion: completion)
        }, onSuccess: { [weak self] recipes in
            self?.recipes = recipes
        })
    }
    
    func filterRecipesByIngredients(ingredients: [String]) -> [Recipe] {
        return recipes.filter { recipe in
            ingredients.allSatisfy { ingredient in
                recipe.ingredients?.contains(ingredient) == true
            }
        }
    }
} 