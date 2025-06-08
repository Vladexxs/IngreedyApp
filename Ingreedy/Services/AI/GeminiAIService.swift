import Foundation

// MARK: - Gemini AI Service
@MainActor
class GeminiAIService: ObservableObject {
    static let shared = GeminiAIService()
    
    private let session: URLSession
    private var conversationHistory: [ChatMessage] = []
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = GeminiConfiguration.Limits.timeoutSeconds
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Main Chat Function
    func generateRecipeResponse(
        for message: String,
        userIngredients: [String] = [],
        conversationContext: [ChatMessage] = []
    ) async throws -> AIResponse {
        
        guard GeminiConfiguration.isConfigured else {
            throw AIError.configurationError("API key gerekli")
        }
        
        // Sistem promptu oluştur (Google One Pro avantajları ile)
        let systemPrompt = createAdvancedSystemPrompt()
        
        // Kullanıcı promptu oluştur
        let userPrompt = createUserPrompt(
            message: message,
            ingredients: userIngredients,
            context: conversationContext
        )
        
        // Gemini API'sine istek gönder
        let response = try await callGeminiAPI(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt
        )
        
        // Cevabı parse et
        return parseAIResponse(response, originalMessage: message)
    }
    
    // MARK: - System Prompt
    private func createAdvancedSystemPrompt() -> String {
        return """
        You are an AI cooking assistant for the Ingreedy app. You help users with recipes, cooking tips, and food-related questions.
        
        Keep your responses natural, helpful, and focused on cooking. You can discuss:
        - Recipe suggestions based on available ingredients
        - Cooking techniques and tips
        - Ingredient substitutions
        - Meal planning
        - Nutritional information
        - Cuisine from around the world
        
        Be conversational and friendly. Give practical, actionable advice.
        """
    }
    
    // MARK: - User Prompt Creation
    private func createUserPrompt(
        message: String,
        ingredients: [String],
        context: [ChatMessage]
    ) -> String {
        var prompt = ""
        
        // Available ingredients
        if !ingredients.isEmpty {
            prompt += "Available ingredients: \(ingredients.joined(separator: ", "))\n\n"
        }
        
        // User message
        prompt += "User: \(message)"
        
        return prompt
    }
    
    // MARK: - Gemini API Call
    private func callGeminiAPI(systemPrompt: String, userPrompt: String) async throws -> String {
        let url = URL(string: "\(GeminiConfiguration.baseURL)/models/\(GeminiConfiguration.Model.primary):generateContent?key=\(GeminiConfiguration.apiKey)")!
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: systemPrompt + "\n\n" + userPrompt)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: GeminiConfiguration.Model.temperature,
                maxOutputTokens: GeminiConfiguration.Model.maxTokens,
                candidateCount: 1
            ),
            tools: nil
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("Geçersiz cevap")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.apiError("API Hatası: \(httpResponse.statusCode)")
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = apiResponse.candidates.first?.content.parts.first?.text else {
            throw AIError.noResponse("AI'dan cevap alınamadı")
        }
        
        return content
    }
    
    // MARK: - Removed Components
    // Pro tools configuration removed as we simplified to basic chat
    
    // MARK: - Response Parser
    private func parseAIResponse(_ geminiText: String, originalMessage: String) -> AIResponse {
        // Simple response - just return the AI's natural response
        return AIResponse(
            message: geminiText.isEmpty ? "Sorry, I couldn't generate a response. Please try again! 😊" : geminiText,
            suggestions: [], // No automatic suggestions
            recipes: [], // No automatic recipe parsing
            nutritionInfo: nil,
            hasProFeatures: GeminiConfiguration.hasProFeatures
        )
    }

} 