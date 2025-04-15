import SwiftUI

enum AppColors {
    static let primary = Color(hex: "FF6B6B")
    static let secondary = Color(hex: "FF8E53")
    static let background = LinearGradient(
        gradient: Gradient(colors: [primary, secondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let text = Color.white
    static let buttonText = primary
    static let buttonBackground = Color.white
} 