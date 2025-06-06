import SwiftUI

struct LoginTextField: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    let isSecure: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Spacing.small) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.text)
            
            if isSecure {
                SecureField("", text: text)
                    .placeholder(when: text.wrappedValue.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(AppColors.primary.opacity(0.8))
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(AppConstants.CornerRadius.medium)
                    .shadow(
                        color: AppConstants.Shadow.small,
                        radius: AppConstants.Shadow.radius,
                        x: 0,
                        y: AppConstants.Shadow.y
                    )
                    .textContentType(.password)
                    .foregroundColor(AppColors.text)
            } else {
                TextField("", text: text)
                    .placeholder(when: text.wrappedValue.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(AppColors.primary.opacity(0.8))
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(AppConstants.CornerRadius.medium)
                    .shadow(
                        color: AppConstants.Shadow.small,
                        radius: AppConstants.Shadow.radius,
                        x: 0,
                        y: AppConstants.Shadow.y
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .foregroundColor(AppColors.text)
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            self
            placeholder().opacity(shouldShow ? 1 : 0)
        }
    }
} 