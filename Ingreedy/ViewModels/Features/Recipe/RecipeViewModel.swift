import Foundation
import Combine
import FirebaseFirestore

class RecipeViewModel: BaseViewModel {
    @Published var recipes: [Recipe] = []
    @Published var userFavorites: [Int] = []
    private let recipeService = RecipeService()
    var userId: String?
    
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
    
    func fetchUserFavorites() {
        guard let userId = self.userId else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            let favorites = (snapshot?.data()? ["favorites"] as? [Int]) ?? []
            DispatchQueue.main.async {
                self.userFavorites = favorites
            }
        }
    }

    func addRecipeToFavorites(recipeId: Int) {
        guard let userId = self.userId else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "favorites": FieldValue.arrayUnion([recipeId])
        ]) { _ in
            self.fetchUserFavorites()
        }
    }

    func removeRecipeFromFavorites(recipeId: Int) {
        guard let userId = self.userId else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "favorites": FieldValue.arrayRemove([recipeId])
        ]) { _ in
            self.fetchUserFavorites()
        }
    }
} 