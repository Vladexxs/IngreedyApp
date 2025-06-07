import SwiftUI

struct AnimatedLogoView: View {
    // MARK: - Properties
    private let animationFileName: String
    private let logoSize: CGSize
    
    // MARK: - Initialization
    init(
        animationFileName: String = "orange-chef",
        logoSize: CGSize = CGSize(width: 180, height: 180)
    ) {
        self.animationFileName = animationFileName
        self.logoSize = logoSize
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if isAnimationFileAvailable {
                lottieAnimationView
            } else {
                fallbackChefIcon
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
    
    var fallbackChefIcon: some View {
        Text("👨‍🍳")
            .font(.system(size: 100))
            .frame(width: logoSize.width, height: logoSize.height)
    }
}

// MARK: - Computed Properties
private extension AnimatedLogoView {
    
    var isAnimationFileAvailable: Bool {
        Bundle.main.url(forResource: animationFileName, withExtension: "json") != nil
    }
} 