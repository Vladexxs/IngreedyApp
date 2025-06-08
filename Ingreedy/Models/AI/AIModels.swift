import Foundation

// MARK: - AI Response Models
struct AIResponse {
    let message: String
    let suggestions: [String]
    let recipes: [AIRecipe] // Kept for compatibility but unused
    let nutritionInfo: String? // Kept for compatibility but unused  
    let hasProFeatures: Bool
}

// MARK: - Simplified Models (kept for compatibility)
struct AIRecipe: Identifiable {
    let id: String
    let name: String
    let description: String
    let imageURL: String
    let category: String
    let cuisine: String
    let nutritionInfo: String?
}

// MARK: - Chat Models
struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let recipes: [AIRecipe]
    let suggestions: [String]
    let nutritionInfo: String?
    let hasProFeatures: Bool
    
    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        recipes: [AIRecipe] = [], // Unused but kept for compatibility
        suggestions: [String] = [], // Now empty by default
        nutritionInfo: String? = nil, // Unused but kept for compatibility
        hasProFeatures: Bool = false
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.recipes = recipes
        self.suggestions = suggestions
        self.nutritionInfo = nutritionInfo
        self.hasProFeatures = hasProFeatures
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Gemini API Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
    let tools: [GeminiTool]?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Float
    let maxOutputTokens: Int
    let candidateCount: Int
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

// MARK: - Google Gemini API Models (kept for basic API communication)
struct GeminiTool: Codable {
    let functionDeclarations: [GeminiFunctionDeclaration]?
    let codeExecution: GeminiCodeExecution?
    
    init(functionDeclarations: [GeminiFunctionDeclaration]) {
        self.functionDeclarations = functionDeclarations
        self.codeExecution = nil
    }
    
    init(codeExecution: GeminiCodeExecution) {
        self.functionDeclarations = nil
        self.codeExecution = codeExecution
    }
}

struct GeminiFunctionDeclaration: Codable {
    let name: String
    let description: String
    let parameters: GeminiParameters
}

struct GeminiParameters: Codable {
    let type: String
    let properties: [String: GeminiProperty]
}

struct GeminiProperty: Codable {
    let type: String
    let description: String
}

struct GeminiCodeExecution: Codable {
    // Kept for API compatibility but unused
}

// MARK: - Error Models
enum AIError: LocalizedError {
    case configurationError(String)
    case networkError(String)
    case apiError(String)
    case noResponse(String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Yapılandırma Hatası: \(message)"
        case .networkError(let message):
            return "Ağ Hatası: \(message)"
        case .apiError(let message):
            return "API Hatası: \(message)"
        case .noResponse(let message):
            return "Cevap Yok: \(message)"
        case .parsingError(let message):
            return "Ayrıştırma Hatası: \(message)"
        }
    }
} 