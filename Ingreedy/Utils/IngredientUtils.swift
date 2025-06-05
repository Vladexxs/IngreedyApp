import Foundation

// MARK: - Ingredient Utility Models

/// Ingredient category for organizing ingredients
struct IngredientCategory: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let ingredients: [String]
    
    var isNotEmpty: Bool {
        return !ingredients.isEmpty
    }
}

/// Result model for partial recipe matches
struct PartialMatchResult: Identifiable {
    let id = UUID()
    let recipe: Recipe
    let matchingIngredients: [String]
    let missingIngredients: [String]
    
    var matchPercentage: Int {
        let total = matchingIngredients.count + missingIngredients.count
        guard total > 0 else { return 0 }
        return Int((Double(matchingIngredients.count) / Double(total)) * 100)
    }
    
    var matchRatio: Double {
        let total = matchingIngredients.count + missingIngredients.count
        guard total > 0 else { return 0.0 }
        return Double(matchingIngredients.count) / Double(total)
    }
}

// MARK: - Ingredient Categories Data
extension IngredientCategory {
    /// Creates categorized ingredient lists from a set of ingredients
    static func createCategories(from ingredients: Set<String>) -> [IngredientCategory] {
        let ingredientsArray = Array(ingredients).sorted()
        
        let categories = [
            IngredientCategory(
                emoji: "🥩",
                name: "Meat & Protein",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return meatKeywords.contains { lower.contains($0) }
                }
            ),
            IngredientCategory(
                emoji: "🥬",
                name: "Vegetables",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return vegetableKeywords.contains { lower.contains($0) }
                }
            ),
            IngredientCategory(
                emoji: "🧀",
                name: "Dairy Products",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return dairyKeywords.contains { lower.contains($0) }
                }
            ),
            IngredientCategory(
                emoji: "🌾",
                name: "Grains & Carbs",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return grainKeywords.contains { lower.contains($0) }
                }
            ),
            IngredientCategory(
                emoji: "🥄",
                name: "Spices & Seasonings",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return spiceKeywords.contains { lower.contains($0) }
                }
            ),
            IngredientCategory(
                emoji: "🐟",
                name: "Seafood",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return seafoodKeywords.contains { lower.contains($0) }
                }
            )
        ].filter { $0.isNotEmpty }
        
        return categories
    }
    
    // MARK: - Keyword Collections
    private static let meatKeywords = [
        "chicken", "beef", "pork", "turkey", "lamb", "bacon", "ham", 
        "sausage", "egg", "duck", "veal"
    ]
    
    private static let vegetableKeywords = [
        "onion", "tomato", "carrot", "potato", "garlic", "pepper",
        "lettuce", "spinach", "cabbage", "broccoli", "celery", "cucumber",
        "mushroom", "zucchini", "eggplant", "corn", "peas", "beans"
    ]
    
    private static let dairyKeywords = [
        "cheese", "milk", "butter", "cream", "yogurt", "mozzarella",
        "parmesan", "cheddar"
    ]
    
    private static let grainKeywords = [
        "rice", "pasta", "bread", "flour", "oats", "quinoa",
        "noodles", "tortilla", "barley", "wheat"
    ]
    
    private static let spiceKeywords = [
        "salt", "pepper", "paprika", "cumin", "oregano", "basil",
        "thyme", "rosemary", "cinnamon", "ginger", "turmeric", "chili"
    ]
    
    private static let seafoodKeywords = [
        "salmon", "tuna", "shrimp", "fish", "crab", "lobster", "cod"
    ]
} 