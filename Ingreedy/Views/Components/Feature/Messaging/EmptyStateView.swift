import SwiftUI

struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(AppColors.secondary)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
    }
} 