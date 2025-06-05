import Foundation

// MARK: - Recipe Model
struct Recipe: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let ingredients: [String]?
    let instructions: [String]?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let servings: Int?
    let difficulty: String?
    let cuisine: String?
    let caloriesPerServing: Int?
    let tags: [String]?
    let image: String?
    let rating: Double?
    
    // MARK: - Computed Properties
    var totalTime: Int {
        (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0)
    }
    
    var difficultyLevel: DifficultyLevel {
        guard let difficulty = difficulty else { return .medium }
        return DifficultyLevel(rawValue: difficulty.lowercased()) ?? .medium
    }
    
    var displayIngredients: [String] {
        ingredients ?? []
    }
    
    var displayInstructions: [String] {
        instructions ?? []
    }
}

// MARK: - Recipe Extensions
extension Recipe {
    /// Checks if recipe contains all specified ingredients
    func containsIngredients(_ searchIngredients: [String]) -> Bool {
        let recipeIngredients = displayIngredients.map { $0.lowercased() }
        return searchIngredients.allSatisfy { searchIngredient in
            recipeIngredients.contains { ingredient in
                ingredient.contains(searchIngredient.lowercased())
            }
        }
    }
    
    /// Returns count of matching ingredients with user ingredients
    func matchingIngredientsCount(with userIngredients: [String]) -> Int {
        let userIngredientsSet = Set(userIngredients.map { $0.lowercased() })
        let recipeIngredientsSet = Set(displayIngredients.map { $0.lowercased() })
        return userIngredientsSet.intersection(recipeIngredientsSet).count
    }
    
    /// Calculates match percentage for partial matches
    func matchPercentage(with userIngredients: [String]) -> Int {
        guard !displayIngredients.isEmpty else { return 0 }
        let matchingCount = matchingIngredientsCount(with: userIngredients)
        return Int((Double(matchingCount) / Double(displayIngredients.count)) * 100)
    }
}

// MARK: - Supporting Enums
enum DifficultyLevel: String, CaseIterable, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
    
    var emoji: String {
        switch self {
        case .easy: return "😊"
        case .medium: return "🤔"
        case .hard: return "��"
        }
    }
} 