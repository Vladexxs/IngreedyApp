import SwiftUI

struct ModernButton: View {
    let title: String
    let action: () -> Void
    let icon: String?
    let style: ButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case danger
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return AppColors.accent
            case .secondary:
                return AppColors.secondary.opacity(0.2)
            case .outline:
                return Color.clear
            case .danger:
                return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .danger:
                return .white
            case .secondary:
                return AppColors.text
            case .outline:
                return AppColors.accent
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline:
                return AppColors.accent
            default:
                return Color.clear
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .outline:
                return 2
            default:
                return 0
            }
        }
    }
    
    @State private var isPressed = false
    
    init(
        title: String,
        action: @escaping () -> Void,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.action = action
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isLoading ? "Loading..." : title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(style.foregroundColor.opacity(isDisabled ? 0.6 : 1.0))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                style.backgroundColor.opacity(isDisabled ? 0.5 : 1.0)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor.opacity(isDisabled ? 0.5 : 1.0), lineWidth: style.borderWidth)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .shadow(
                color: isDisabled ? Color.clear : style.backgroundColor.opacity(0.3),
                radius: isPressed ? 2 : 6,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .disabled(isLoading || isDisabled)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// Custom modifier for press events
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
} 