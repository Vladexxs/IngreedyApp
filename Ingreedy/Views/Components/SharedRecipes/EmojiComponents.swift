import SwiftUI

struct EmojiMenu: View {
    var onSelect: (String) -> Void
    @State private var selectedEmoji: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            EmojiReactionButton(emoji: "👍", isSelected: selectedEmoji == "👍") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedEmoji = "👍"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onSelect("like")
                }
            }
            
            EmojiReactionButton(emoji: "😐", isSelected: selectedEmoji == "😐") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedEmoji = "😐"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onSelect("neutral")
                }
            }
            
            EmojiReactionButton(emoji: "👎", isSelected: selectedEmoji == "👎") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedEmoji = "👎"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onSelect("dislike")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(AppColors.primary.opacity(0.9))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
    }
}

struct EmojiReactionButton: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isSelected ? 0.4 : 0), lineWidth: 1)
                        )
                )
                .scaleEffect(isPressed ? 0.85 : (isSelected ? 1.2 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Helper Functions

extension View {
    func emojiText(for reaction: String) -> String {
        switch reaction {
        case "like": return "👍"
        case "neutral": return "😐"
        case "dislike": return "👎"
        default: return ""
        }
    }
} 