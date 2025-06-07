import SwiftUI
import Lottie

/// Splash Loading ekranı görünümü
struct SplashLoadingView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = LoadingViewModel()
    
    // MARK: - Animation States
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var fadeAnimation: Bool = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Arka plan
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.primary,
                    AppColors.accent
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                // Logo ve uygulama adı
                VStack(spacing: 20) {
                    // App Logo/Icon - Basit animasyon
                    VStack(spacing: 15) {
                        // Main logo with simple animation
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // App name with fade animation
                        Text("Ingreedy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(fadeAnimation ? 1.0 : 0.7)
                    }
                    .onAppear {
                        // Logo entrance animation
                        withAnimation(.easeOut(duration: 1.0)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                        }
                        
                        // Fade animation for text
                        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                            fadeAnimation = true
                        }
                    }
                }
                
                Spacer().frame(height: 40)
                
                // Ana animasyon - Sadece orange-chef veya white-chef
                Group {
                    if Bundle.main.path(forResource: "orange-chef", ofType: "json") != nil {
                        // Orange chef animasyonu (ana seçenek)
                        LottieView(name: "orange-chef", loopMode: .loop)
                            .frame(width: 250, height: 250)
                    } else if Bundle.main.path(forResource: "white-chef", ofType: "json") != nil {
                        // White chef animasyonu (fallback)
                        LottieView(name: "white-chef", loopMode: .loop)
                            .frame(width: 250, height: 250)
                    } else {
                        // Final fallback: Simple chef icon
                        VStack {
                            Image(systemName: "person.crop.artframe")
                                .font(.system(size: 100))
                                .foregroundColor(.white.opacity(0.8))
                                .scaleEffect(fadeAnimation ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: fadeAnimation)
                            
                            Text("👨‍🍳")
                                .font(.system(size: 60))
                                .scaleEffect(fadeAnimation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: fadeAnimation)
                        }
                    }
                }
                .frame(height: 250)
                
                Spacer().frame(height: 40)
                
                // Loading text ve progress
                VStack(spacing: 25) {
                    // Loading mesajı
                    Text("Lezzetli tarifler hazırlanıyor...")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(fadeAnimation ? 1.0 : 0.7)
                    
                    // Progress bar
                    VStack(spacing: 10) {
                        // Progress bar arka plan
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.3))
                                .frame(height: 8)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white)
                                .frame(width: CGFloat(viewModel.progress) * UIScreen.main.bounds.width * 0.7, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.7)
                        
                        // Progress percentage
                        Text("\(Int(viewModel.progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            viewModel.startLoading()
        }
        .onChange(of: viewModel.isLoadingComplete) { completed in
            if completed {
                withAnimation(.easeInOut(duration: 0.5)) {
                    router.onLoadingComplete()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashLoadingView()
        .environmentObject(Router())
} 