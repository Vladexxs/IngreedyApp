import SwiftUI

struct BubbleWithTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tailWidth: CGFloat = 14
        let tailHeight: CGFloat = 18
        let cornerRadius: CGFloat = 20
        // Main bubble
        path.addRoundedRect(in: CGRect(x: tailWidth, y: 0, width: rect.width - tailWidth, height: rect.height), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        // Tail (left middle)
        path.move(to: CGPoint(x: tailWidth, y: rect.midY - tailHeight/2))
        path.addLine(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: tailWidth, y: rect.midY + tailHeight/2))
        path.closeSubpath()
        return path
    }
}

struct BubbleWithTailRight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tailWidth: CGFloat = 14
        let tailHeight: CGFloat = 18
        let cornerRadius: CGFloat = 20
        // Main bubble
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width - tailWidth, height: rect.height), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        // Tail (right middle)
        path.move(to: CGPoint(x: rect.width - tailWidth, y: rect.midY - tailHeight/2))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width - tailWidth, y: rect.midY + tailHeight/2))
        path.closeSubpath()
        return path
    }
} 