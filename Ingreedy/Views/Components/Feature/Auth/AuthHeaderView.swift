import SwiftUI

struct AuthHeaderView: View {
    // MARK: - Properties
    private let title: String
    private let subtitle: String
    private let showAnimation: Bool
    
    // MARK: - Initialization
    init(
        title: String = "Ingreedy",
        subtitle: String = "Discover & Share Amazing Recipes",
        showAnimation: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showAnimation = showAnimation
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: HeaderSpacing.main) {
            logoAndTitleSection
        }
        .padding(.bottom, HeaderSpacing.bottom)
    }
}

// MARK: - Private Views
private extension AuthHeaderView {
    
    var logoAndTitleSection: some View {
        VStack(spacing: HeaderSpacing.logoToTitle) {
            if showAnimation {
                AnimatedLogoView()
            } else {
                staticLogoView
            }
            
            titleSection
        }
    }
    
    var staticLogoView: some View {
        Image(systemName: "fork.knife.circle.fill")
            .font(.system(size: 80, weight: .light))
            .foregroundStyle(logoGradient)
            .shadow(
                color: AppColors.accent.opacity(0.3),
                radius: 10,
                x: 0,
                y: 5
            )
    }
    
    var titleSection: some View {
        VStack(spacing: HeaderSpacing.titleToSubtitle) {
            titleText
            subtitleText
        }
    }
    
    var titleText: some View {
        Text(title)
            .font(HeaderFonts.title)
            .foregroundStyle(titleGradient)
            .shadow(
                color: AppColors.primary.opacity(0.2),
                radius: 6,
                x: 0,
                y: 3
            )
            .offset(y: HeaderLayout.titleOffset)
    }
    
    var subtitleText: some View {
        Text(subtitle)
            .font(HeaderFonts.subtitle)
            .foregroundColor(AppColors.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, HeaderSpacing.subtitlePadding)
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
    
    var titleGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppColors.primary,
                AppColors.accent.opacity(0.8)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Design Constants
private enum HeaderSpacing {
    static let main: CGFloat = 8
    static let logoToTitle: CGFloat = 4
    static let titleToSubtitle: CGFloat = 8
    static let subtitlePadding: CGFloat = 4
    static let bottom: CGFloat = 8
}

private enum HeaderFonts {
    static let title: Font = .system(size: 36, weight: .bold, design: .rounded)
    static let subtitle: Font = .system(size: 16, weight: .medium)
}

private enum HeaderLayout {
    static let titleOffset: CGFloat = -8
}

// MARK: - Convenience Views
struct LoginHeaderView: View {
    var body: some View {
        AuthHeaderView(
            title: "Ingreedy",
            subtitle: "Discover & Share Amazing Recipes",
            showAnimation: true
        )
    }
}

struct RegisterHeaderView: View {
    var body: some View {
        AuthHeaderView(
            title: "Create Account",
            subtitle: "Join our community today",
            showAnimation: false
        )
    }
}

struct ForgotPasswordHeaderView: View {
    var body: some View {
        AuthHeaderView(
            title: "Forgot Password?",
            subtitle: "No worries! Enter your email address",
            showAnimation: false
        )
    }
} 