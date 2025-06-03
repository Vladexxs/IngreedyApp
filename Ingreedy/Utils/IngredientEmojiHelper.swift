import Foundation

// MARK: - Ingredient Emoji Helper
struct IngredientEmojiHelper {
    static func getEmoji(for ingredient: String) -> String {
        let lowercased = ingredient.lowercased()
        
        // Meat & Poultry
        if lowercased.contains("chicken") || lowercased.contains("poultry") { return "🐔" }
        if lowercased.contains("beef") || lowercased.contains("steak") { return "🥩" }
        if lowercased.contains("pork") || lowercased.contains("ham") || lowercased.contains("bacon") { return "🥓" }
        if lowercased.contains("turkey") { return "🦃" }
        if lowercased.contains("lamb") { return "🐑" }
        if lowercased.contains("sausage") { return "🌭" }
        
        // Seafood
        if lowercased.contains("fish") || lowercased.contains("salmon") || lowercased.contains("tuna") { return "🐟" }
        if lowercased.contains("shrimp") || lowercased.contains("prawn") { return "🦐" }
        if lowercased.contains("crab") { return "🦀" }
        if lowercased.contains("lobster") { return "🦞" }
        
        // Vegetables
        if lowercased.contains("tomato") { return "🍅" }
        if lowercased.contains("onion") { return "🧅" }
        if lowercased.contains("carrot") { return "🥕" }
        if lowercased.contains("potato") { return "🥔" }
        if lowercased.contains("garlic") { return "🧄" }
        if lowercased.contains("pepper") && !lowercased.contains("bell") { return "🌶️" }
        if lowercased.contains("bell pepper") || (lowercased.contains("pepper") && lowercased.contains("bell")) { return "🫑" }
        if lowercased.contains("lettuce") || lowercased.contains("salad") { return "🥬" }
        if lowercased.contains("spinach") { return "🥬" }
        if lowercased.contains("broccoli") { return "🥦" }
        if lowercased.contains("corn") { return "🌽" }
        if lowercased.contains("mushroom") { return "🍄" }
        if lowercased.contains("avocado") { return "🥑" }
        if lowercased.contains("cucumber") { return "🥒" }
        if lowercased.contains("eggplant") { return "🍆" }
        
        // Fruits
        if lowercased.contains("apple") { return "🍎" }
        if lowercased.contains("banana") { return "🍌" }
        if lowercased.contains("orange") { return "🍊" }
        if lowercased.contains("lemon") { return "🍋" }
        if lowercased.contains("lime") { return "🟢" }
        if lowercased.contains("strawberry") { return "🍓" }
        
        // Dairy & Eggs
        if lowercased.contains("cheese") { return "🧀" }
        if lowercased.contains("milk") { return "🥛" }
        if lowercased.contains("egg") { return "🥚" }
        if lowercased.contains("butter") { return "🧈" }
        if lowercased.contains("cream") { return "🥛" }
        if lowercased.contains("yogurt") { return "🥛" }
        
        // Grains & Carbs
        if lowercased.contains("rice") { return "🍚" }
        if lowercased.contains("pasta") || lowercased.contains("spaghetti") || lowercased.contains("noodle") { return "🍝" }
        if lowercased.contains("bread") { return "🍞" }
        if lowercased.contains("flour") { return "🌾" }
        if lowercased.contains("oats") || lowercased.contains("oatmeal") { return "🥣" }
        
        // Legumes & Nuts
        if lowercased.contains("bean") { return "🫘" }
        if lowercased.contains("lentil") { return "🫘" }
        if lowercased.contains("peanut") { return "🥜" }
        if lowercased.contains("almond") || lowercased.contains("walnut") || lowercased.contains("nut") { return "🥜" }
        
        // Herbs & Spices
        if lowercased.contains("basil") || lowercased.contains("herb") { return "🌿" }
        if lowercased.contains("salt") { return "🧂" }
        if lowercased.contains("sugar") { return "🍯" }
        if lowercased.contains("honey") { return "🍯" }
        if lowercased.contains("oil") || lowercased.contains("olive") { return "🫒" }
        if lowercased.contains("vinegar") { return "🍾" }
        
        // Default
        return "🥄"
    }
} 