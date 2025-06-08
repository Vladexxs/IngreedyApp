import SwiftUI

struct AIAssistantCard: View {
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var gradientAnimation = false
    let userIngredients: [String]
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background with animated gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: gradientAnimation ? 
                                [Color.orange.opacity(0.9), Color.red.opacity(0.7), Color.pink.opacity(0.5)] :
                                [Color.red.opacity(0.8), Color.orange.opacity(0.7), Color.yellow.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.orange.opacity(0.4),
                        radius: pulseAnimation ? 20 : 15,
                        x: 0,
                        y: pulseAnimation ? 8 : 5
                    )
                
                // Floating particles effect
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                        .offset(
                            x: CGFloat.random(in: -100...100),
                            y: CGFloat.random(in: -50...50)
                        )
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.8 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 2...4))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
                
                // Content
                VStack(spacing: 20) {
                    // Header with animated icon
                    HStack(spacing: 16) {
                        // Animated Chef Icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            
                            Text("👨‍🍳")
                                .font(.system(size: 28))
                                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Title with gradient text
                            Text("ChefMate")
                                .font(.title2.bold())
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Your AI Cooking Companion")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // AI Badge with glow effect
                        HStack(spacing: 6) {
                            Text("AI")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.3))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .shadow(color: .orange.opacity(0.4), radius: 4)
                        }
                    }
                    
                    // Description
                    Text(getDescription())
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Ingredients section (if available)
                    if !userIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your ingredients:")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.8))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(userIngredients.prefix(4).enumerated()), id: \.offset) { index, ingredient in
                                        Text(ingredient)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.15))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                            )
                                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                                            .animation(
                                                Animation.easeInOut(duration: 2)
                                                    .repeatForever(autoreverses: true)
                                                    .delay(Double(index) * 0.2),
                                                value: isAnimating
                                            )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    
                    // CTA Button with shimmer effect
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(isAnimating ? 180 : 0))
                            
                            Text(getCTAText())
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: .white.opacity(0.2), radius: 8)
                        .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                        
                        Spacer()
                    }
                }
                .padding(24)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                gradientAnimation = true
            }
        }
    }
    
    private func getDescription() -> String {
        return "Ask me about recipes, cooking tips, ingredient substitutions, and more!"
    }
    
    private func getCTAText() -> String {
        if !userIngredients.isEmpty {
            return "Ask ChefMate for recipes"
        } else {
            return "Start chatting with ChefMate"
        }
    }
}

#Preview {
    AIAssistantCard(userIngredients: ["Chicken", "Rice", "Garlic"]) {
        print("Tapped!")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 