import SwiftUI

struct ModernGoogleSignInButton: View {
    let action: () -> Void
    let isLoading: Bool
    
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, isLoading: Bool = false) {
        self.action = action
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.text))
                        .scaleEffect(0.8)
                } else {
                    // Google Icon
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.text)
                }
                
                Text(isLoading ? "Signing in..." : "Continue with Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.secondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .shadow(
                color: isLoading ? Color.clear : Color.black.opacity(0.1),
                radius: isPressed ? 2 : 6,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .disabled(isLoading)
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