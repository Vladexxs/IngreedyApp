import SwiftUI

struct ProfileHeaderView: View {
    var onSettingsTapped: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text("Account")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.primary)
            Spacer()
            Button(action: {
                onSettingsTapped?()
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.primary)
                    .padding(10)
                    .background(AppColors.card)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }
} 