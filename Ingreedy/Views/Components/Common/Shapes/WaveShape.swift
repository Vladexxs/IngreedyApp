import SwiftUI

/// Dalgalı şekil oluşturan Shape
struct WaveShape: Shape {
    let amplitude: CGFloat
    let frequency: CGFloat
    let phase: CGFloat
    
    init(amplitude: CGFloat = 50, frequency: CGFloat = 2, phase: CGFloat = 0) {
        self.amplitude = amplitude
        self.frequency = frequency
        self.phase = phase
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.7 // Dalganın orta yüksekliği
        
        // Başlangıç noktası
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Üst kenarı çiz
        path.addLine(to: CGPoint(x: width, y: 0))
        
        // Sağ kenarı çiz
        path.addLine(to: CGPoint(x: width, y: midHeight))
        
        // Dalgalı alt kısmı çiz
        for x in stride(from: width, through: 0, by: -2) {
            let relativeX = x / width
            let y = midHeight + amplitude * sin(frequency * .pi * relativeX + phase)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Sol kenarı kapat
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        return path
    }
}

/// Çoklu dalga efekti için animasyonlu wrapper
struct AnimatedWaveBackground: View {
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Ana gradient arka plan
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.1),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // İlk dalga katmanı
            WaveShape(amplitude: 40, frequency: 1.5, phase: phase1)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.3),
                            Color.orange.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // İkinci dalga katmanı
            WaveShape(amplitude: 30, frequency: 2, phase: phase2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase1 = .pi * 2
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase2 = .pi * 2
            }
        }
    }
} 