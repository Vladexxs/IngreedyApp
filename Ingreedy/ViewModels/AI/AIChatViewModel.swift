import Foundation
import SwiftUI

@MainActor
class AIChatViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var currentMessage: String = ""
    @Published var isTyping: Bool = false
    
    // MARK: - Properties
    private let aiService = GeminiAIService.shared
    var userIngredients: [String] = []
    
    override init() {
        super.init()
        addWelcomeMessage()
    }
    
    // MARK: - Public Methods
    func sendMessage() async {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = currentMessage
        currentMessage = ""
        
        // Add user message
        let userChatMessage = ChatMessage(
            content: userMessage,
            isUser: true,
            hasProFeatures: false
        )
        messages.append(userChatMessage)
        
        // Generate AI response
        await generateAIResponse(for: userMessage)
    }
    
    func clearChat() {
        messages.removeAll()
        addWelcomeMessage()
    }
    
    func getModelInfo() -> String {
        return "ChefMate • Ingreedy"
    }
    
    // MARK: - Private Methods
    private func addWelcomeMessage() {
        let welcomeContent = """
        👨‍🍳 Hello! I'm ChefMate, your personal AI cooking companion!
        
        I can help you with recipes, cooking tips, and food-related questions. Just tell me what ingredients you have or what you'd like to cook! 🍳✨
        """
        
        let welcomeMessage = ChatMessage(
            content: welcomeContent,
            isUser: false,
            suggestions: [],
            hasProFeatures: false
        )
        
        messages.append(welcomeMessage)
    }
    
    private func generateAIResponse(for userMessage: String) async {
        isTyping = true
        
        do {
            // Simulate typing delay
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Get AI response
            let response = try await aiService.generateRecipeResponse(
                for: userMessage,
                userIngredients: userIngredients,
                conversationContext: []
            )
            
            // Create AI message
            let aiMessage = ChatMessage(
                content: response.message,
                isUser: false,
                recipes: response.recipes,
                suggestions: response.suggestions,
                nutritionInfo: response.nutritionInfo,
                hasProFeatures: response.hasProFeatures
            )
            
            // Add message
            messages.append(aiMessage)
            
        } catch {
            handleError(error)
        }
        
        isTyping = false
    }
    
    override func handleError(_ error: Error) {
        let errorMessage = ChatMessage(
            content: "😔 Sorry, I encountered an issue:\n\n\(error.localizedDescription)\n\nPlease try again.",
            isUser: false,
            suggestions: [],
            hasProFeatures: false
        )
        
        messages.append(errorMessage)
    }
} 