import SwiftUI

enum AppConstants {
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 15
    }
    
    enum Shadow {
        static let small = Color.black.opacity(0.1)
        static let radius: CGFloat = 5
        static let y: CGFloat = 2
    }
    
    enum ImageSize {
        static let logo: CGFloat = 120
    }
    
    enum FontSize {
        static let title: CGFloat = 40
    }
} 