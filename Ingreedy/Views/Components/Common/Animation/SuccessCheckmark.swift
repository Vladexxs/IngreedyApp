import SwiftUI

struct SuccessCheckmark: View {
    @State private var animateStroke = false
    @State private var animateScale = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.green)
                .frame(width: 50, height: 50)
                .scaleEffect(animateScale ? 1.1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateScale)
            
            // Checkmark path
            Path { path in
                path.move(to: CGPoint(x: 15, y: 25))
                path.addLine(to: CGPoint(x: 22, y: 32))
                path.addLine(to: CGPoint(x: 35, y: 18))
            }
            .trim(from: 0, to: animateStroke ? 1 : 0)
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: 50, height: 50)
            .animation(.easeInOut(duration: 0.5).delay(0.2), value: animateStroke)
        }
        .onAppear {
            animateScale = true
            animateStroke = true
        }
    }
}

#Preview {
    SuccessCheckmark()
} 