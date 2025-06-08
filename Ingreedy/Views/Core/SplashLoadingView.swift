import SwiftUI
import Lottie

/// Splash Loading ekranı görünümü
struct SplashLoadingView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = LoadingViewModel()
    
    // MARK: - Animation States
    @State private var currentTipIndex = 0
    @State private var tipOpacity: Double = 1.0
    @State private var tipOffset: CGFloat = 0
    @State private var glowAnimation = false
    
    // MARK: - Tips
    private let appTips = [
        "🍽️ Discover amazing recipes from around the world",
        "📱 Save your favorite dishes for quick access",
        "🔍 Search ingredients to find perfect recipes",
        "👨‍🍳 Step-by-step cooking instructions await you",
        "⭐ Rate and review recipes to help others"
    ]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Enhanced Background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: AppColors.primary, location: 0.0),
                    .init(color: AppColors.primary.opacity(0.8), location: 0.3),
                    .init(color: AppColors.accent.opacity(0.9), location: 0.7),
                    .init(color: AppColors.accent, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle pattern overlay
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(.white.opacity(0.03))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 150, y: 300)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main Animation Container
                VStack(spacing: 25) {
                    // Lottie Animation with glow effect
                    ZStack {
                        // Glow background
                        Circle()
                            .fill(.white.opacity(glowAnimation ? 0.2 : 0.1))
                            .frame(width: 400, height: 400)
                            .blur(radius: 30)
                            .scaleEffect(glowAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowAnimation)
                        
                        // Main animation
                        LottieView(name: "splash_screen_animation", loopMode: .loop)
                            .frame(width: 350, height: 350)
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    }
                    
                    // Animated Tips Section
                    VStack(spacing: 8) {
                        Text("💡 Pro Tip")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(1.5)
                        
                        Text(appTips[currentTipIndex])
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(tipOpacity)
                            .offset(y: tipOffset)
                            .frame(height: 45)
                            .padding(.horizontal, 30)
                    }
                    .padding(.vertical, 15)
                }
                
                Spacer().frame(height: 20)
                
                // Enhanced Progress Section
                VStack(spacing: 15) {
                    // Loading message with pulse
                    Text("Preparing delicious recipes...")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .opacity(glowAnimation ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowAnimation)
                    
                    // Enhanced Progress bar
                    VStack(spacing: 8) {
                        // Progress bar with better styling
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white.opacity(0.2))
                                .frame(height: 12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                            
                            // Progress fill with gradient
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: CGFloat(viewModel.progress) * UIScreen.main.bounds.width * 0.65, height: 12)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                                .shadow(color: .white.opacity(0.5), radius: 4, x: 0, y: 0)
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.65)
                        
                        // Progress percentage with clean styling
                        Text("\(Int(viewModel.progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            viewModel.startLoading()
            startGlowAnimation()
            startTipRotation()
        }
        .onChange(of: viewModel.isLoadingComplete) { completed in
            if completed {
                withAnimation(.easeInOut(duration: 0.5)) {
                    router.onLoadingComplete()
                }
            }
        }
    }
    
    // MARK: - Animation Functions
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowAnimation = true
        }
    }
    
    private func startTipRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                tipOpacity = 0.0
                tipOffset = -10
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentTipIndex = Int.random(in: 0..<appTips.count)
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    tipOpacity = 1.0
                    tipOffset = 0
                }
            }
        }
    }
}

// MARK: - Backdrop Blur Helper
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - View Extension for Backdrop
extension View {
    func backdrop<T: View>(_ view: T) -> some View {
        self.overlay(view)
    }
}

// MARK: - Preview
#Preview {
    SplashLoadingView()
        .environmentObject(Router())
} 