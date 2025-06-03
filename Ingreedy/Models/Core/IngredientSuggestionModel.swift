import Foundation

// MARK: - Ingredient Suggestion Models

struct IngredientCategory {
    let emoji: String
    let name: String
    let ingredients: [String]
    
    var isNotEmpty: Bool {
        !ingredients.isEmpty
    }
}

struct PartialMatchResult {
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
    static func createCategories(from ingredients: Set<String>) -> [IngredientCategory] {
        let ingredientsArray = Array(ingredients)
        
        return [
            IngredientCategory(
                emoji: "🥩",
                name: "Meat & Protein",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return lower.contains("chicken") || lower.contains("beef") || lower.contains("pork") ||
                           lower.contains("turkey") || lower.contains("lamb") || lower.contains("bacon") ||
                           lower.contains("ham") || lower.contains("sausage") || lower.contains("egg")
                }
            ),
            IngredientCategory(
                emoji: "🥬",
                name: "Vegetables",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return lower.contains("onion") || lower.contains("tomato") || lower.contains("carrot") ||
                           lower.contains("potato") || lower.contains("garlic") || lower.contains("pepper") ||
                           lower.contains("lettuce") || lower.contains("spinach") || lower.contains("cabbage") ||
                           lower.contains("broccoli") || lower.contains("celery") || lower.contains("cucumber")
                }
            ),
            IngredientCategory(
                emoji: "🧀",
                name: "Dairy Products",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return lower.contains("cheese") || lower.contains("milk") || lower.contains("butter") ||
                           lower.contains("cream") || lower.contains("yogurt") || lower.contains("mozzarella") ||
                           lower.contains("parmesan") || lower.contains("cheddar")
                }
            ),
            IngredientCategory(
                emoji: "🌾",
                name: "Grains & Carbs",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return lower.contains("rice") || lower.contains("pasta") || lower.contains("bread") ||
                           lower.contains("flour") || lower.contains("oats") || lower.contains("quinoa") ||
                           lower.contains("noodles") || lower.contains("tortilla")
                }
            ),
            IngredientCategory(
                emoji: "🥄",
                name: "Spices & Seasonings",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return lower.contains("salt") || lower.contains("pepper") || lower.contains("paprika") ||
                           lower.contains("cumin") || lower.contains("oregano") || lower.contains("basil") ||
                           lower.contains("thyme") || lower.contains("rosemary") || lower.contains("cinnamon") ||
                           lower.contains("ginger") || lower.contains("turmeric") || lower.contains("chili")
                }
            ),
            IngredientCategory(
                emoji: "🐟",
                name: "Seafood",
                ingredients: ingredientsArray.filter { ingredient in
                    let lower = ingredient.lowercased()
                    return lower.contains("salmon") || lower.contains("tuna") || lower.contains("shrimp") ||
                           lower.contains("fish") || lower.contains("crab") || lower.contains("lobster") ||
                           lower.contains("cod") || lower.contains("tilapia")
                }
            )
        ].filter { $0.isNotEmpty }
    }
} 