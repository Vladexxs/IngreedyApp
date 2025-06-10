import Foundation

// MARK: - AI Response Models
struct AIResponse {
    let message: String
    let suggestions: [String]
    let hasProFeatures: Bool
}

// MARK: - Chat Models
struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let suggestions: [String]
    let hasProFeatures: Bool
    
    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        suggestions: [String] = [],
        hasProFeatures: Bool = false
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.suggestions = suggestions
        self.hasProFeatures = hasProFeatures
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Essential Gemini API Models
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

// MARK: - Minimal Tool Support (for API compatibility)
struct GeminiTool: Codable {
    // Empty struct for API compatibility - tools are disabled
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
            return "Configuration Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .apiError(let message):
            return "API Error: \(message)"
        case .noResponse(let message):
            return "No Response: \(message)"
        case .parsingError(let message):
            return "Parsing Error: \(message)"
        }
    }
} 