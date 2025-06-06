import SwiftUI

struct AnimatedLogoView: View {
    // MARK: - Properties
    private let animationFileName: String
    private let fallbackIcon: String
    private let logoSize: CGSize
    
    // MARK: - Initialization
    init(
        animationFileName: String = "logo-animation",
        fallbackIcon: String = "fork.knife.circle.fill",
        logoSize: CGSize = CGSize(width: 150, height: 150)
    ) {
        self.animationFileName = animationFileName
        self.fallbackIcon = fallbackIcon
        self.logoSize = logoSize
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if isAnimationFileAvailable {
                lottieAnimationView
            } else {
                fallbackSystemIconView
            }
        }
    }
}

// MARK: - Private Views
private extension AnimatedLogoView {
    
    var lottieAnimationView: some View {
        LottieView(
            name: animationFileName,
            loopMode: .playOnce,
            animationSpeed: 1.0
        )
        .frame(width: logoSize.width, height: logoSize.height)
    }
    
    var fallbackSystemIconView: some View {
        Image(systemName: fallbackIcon)
            .font(.system(size: 80, weight: .light))
            .foregroundStyle(logoGradient)
            .shadow(
                color: AppColors.accent.opacity(0.3),
                radius: 10,
                x: 0,
                y: 5
            )
    }
    
    var logoGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppColors.accent,
                AppColors.accent.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Computed Properties
private extension AnimatedLogoView {
    
    var isAnimationFileAvailable: Bool {
        Bundle.main.url(forResource: animationFileName, withExtension: "json") != nil
    }
} 