import SwiftUI

struct HomeHeaderView: View {
    let userName: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
                Text("Welcome,")
                    .font(.system(size: AppConstants.FontSize.body))
                    .foregroundColor(AppColors.text)
                Text(userName)
                    .font(.system(size: AppConstants.FontSize.title, weight: .bold))
                    .foregroundColor(AppColors.text)
            }
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.text)
            }
        }
        .padding(.horizontal, AppConstants.Spacing.extraLarge)
        .padding(.top, AppConstants.Spacing.extraLarge)
    }
} 