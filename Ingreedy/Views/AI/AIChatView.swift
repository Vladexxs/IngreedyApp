import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    let userIngredients: [String]
    
    init(userIngredients: [String] = []) {
        self.userIngredients = userIngredients
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat Header with Pro Badge
                    chatHeader
                    
                    // Messages
                    messagesView
                    
                    // Input Section
                    inputSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .onAppear {
                viewModel.userIngredients = userIngredients
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("ChefMate")
                            .font(.headline.bold())
                            .foregroundColor(AppColors.primary)
                        
                        // AI Badge
                        Text("AI")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                    
                    Text(viewModel.getModelInfo())
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 16) {
                    // Clear Chat
                    Button(action: { viewModel.clearChat() }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(AppColors.secondary.opacity(0.3))
        }
        .background(AppColors.card)
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    // Typing Indicator
                    if viewModel.isTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                    
                    // Bottom spacer
                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .onChange(of: viewModel.messages.count) { _ in
                // Auto scroll to bottom
                withAnimation(.easeOut(duration: 0.5)) {
                    if let lastMessage = viewModel.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isTyping) { isTyping in
                if isTyping {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(AppColors.secondary.opacity(0.3))
            
            HStack(spacing: 12) {
                // Text Input
                HStack(spacing: 8) {
                    TextField("Ask me about recipes, ingredients, or cooking tips...", text: $viewModel.currentMessage, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.primary)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)
                        .onSubmit {
                            Task { await viewModel.sendMessage() }
                        }
                    
                    // AI Indicator
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.card)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isTextFieldFocused ? AppColors.accent.opacity(0.6) : AppColors.secondary.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
                
                // Send Button
                Button(action: {
                    Task { await viewModel.sendMessage() }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: viewModel.currentMessage.isEmpty ? 
                                    [AppColors.secondary.opacity(0.5)] :
                                    [AppColors.accent, AppColors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(22)
                }
                .disabled(viewModel.currentMessage.isEmpty || viewModel.isTyping)
                .scaleEffect(viewModel.currentMessage.isEmpty ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: viewModel.currentMessage.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppColors.background)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
                userMessageView
            } else {
                aiMessageView
                Spacer(minLength: 60)
            }
        }
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AppColors.accent, AppColors.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
            
            Text(message.formattedTime)
                .font(.caption2)
                .foregroundColor(AppColors.secondary)
        }
    }
    
    private var aiMessageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // AI Avatar & Pro Badge
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(16)
                
                Text("ChefMate")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(AppColors.secondary)
            }
            
            // Message Content
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(AppColors.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.card)
                .cornerRadius(18, corners: [.topRight, .bottomLeft, .bottomRight])
            
            // Note: Nutrition info removed as we simplified the AI
            
            // Note: Recipe cards removed as we simplified to pure chat
            

        }
    }
}

// MARK: - Removed Components
// NutritionCard, RecipeCardsView, and AIRecipeCard have been removed
// as we simplified to pure chat interface



// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(16)
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(AppColors.secondary)
                            .frame(width: 8, height: 8)
                            .opacity(animationPhase == Double(index) ? 1.0 : 0.4)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: animationPhase
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.card)
                .cornerRadius(12)
            }
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animationPhase = 0
            withAnimation {
                animationPhase = 2
            }
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    AIChatView(userIngredients: ["tavuk", "domates", "soğan"])
}