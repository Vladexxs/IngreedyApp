import Foundation

// MARK: - API Response Models

/// Response model for recipe API calls
struct RecipeResponse: Codable {
    let recipes: [Recipe]
    let total: Int?
    let skip: Int?
    let limit: Int?
}

/// Response model for single recipe API calls
struct SingleRecipeResponse: Codable {
    let recipe: Recipe?
    let success: Bool
    let message: String?
    
    var isSuccessful: Bool {
        return success && recipe != nil
    }
}

/// Generic API response wrapper
struct APIResponse<T: Codable>: Codable {
    let data: T?
    let success: Bool
    let message: String?
    let error: String?
    
    var isSuccessful: Bool {
        return success && data != nil && error == nil
    }
    
    var errorMessage: String {
        return error ?? message ?? "Unknown error occurred"
    }
}

/// Response model for search operations
struct SearchResponse<T: Codable>: Codable {
    let results: [T]
    let query: String?
    let totalResults: Int?
    let page: Int?
    let hasMore: Bool?
    
    var hasResults: Bool {
        return !results.isEmpty
    }
    
    var resultCount: Int {
        return results.count
    }
} 