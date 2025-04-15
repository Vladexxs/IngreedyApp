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
                SecureField(placeholder, text: text)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
    }
} 