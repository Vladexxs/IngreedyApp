import SwiftUI

struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: animatedProgress >= 1.0 ? 
                            [Color.green, Color.green.opacity(0.7)] :
                            [AppColors.accent, AppColors.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: animatedProgress)
            
            // Content based on progress
            if animatedProgress >= 1.0 {
                // Success checkmark
                SuccessCheckmark()
                    .scaleEffect(size / 80) // Scale relative to ring size
            } else {
                // Percentage text
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Uploading")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            

        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 30) {
        // Progress states
        HStack(spacing: 20) {
            AnimatedProgressRing(progress: 0.0, lineWidth: 3, size: 60)
            AnimatedProgressRing(progress: 0.5, lineWidth: 3, size: 60)  
            AnimatedProgressRing(progress: 1.0, lineWidth: 3, size: 60)
        }
        
        // Large success ring
        AnimatedProgressRing(progress: 1.0, lineWidth: 4, size: 100)
    }
    .padding()
    .background(Color.black.opacity(0.8))
} 