import SwiftUI

struct IngreedyErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    let dismissAction: () -> Void
    private let id = UUID()
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: AppConstants.Spacing.small) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                
                Text(error.localizedDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.9))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom))
        .animation(.spring(), value: id)
    }
}

#Preview {
    IngreedyErrorView(
        error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"]),
        retryAction: nil,
        dismissAction: {}
    )
} 