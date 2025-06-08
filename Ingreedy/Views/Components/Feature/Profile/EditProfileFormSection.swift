import SwiftUI

struct EditProfileFormSection: View {
    @Binding var editedFullName: String
    @Binding var editedUsername: String
    @Binding var isCheckingUsername: Bool
    @Binding var usernameAvailable: Bool?
    
    let originalUsername: String
    let onUsernameChange: (String) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Full Name Field
            modernTextField(
                title: "Full Name",
                text: $editedFullName,
                placeholder: "Enter your full name",
                icon: "person.fill"
            )
            
            // Username Field
            usernameTextField
        }
        .opacity(1)
        .offset(y: 0)
    }
    
    private var usernameTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Username")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                if isCheckingUsername {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                        
                        Text("Checking...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.secondary)
                    }
                } else if let available = usernameAvailable {
                    HStack(spacing: 6) {
                        Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(available ? .green : .red)
                        
                        Text(available ? "Available" : "Taken")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(available ? .green : .red)
                    }
                }
            }
            
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.card)
                        .shadow(color: AppColors.shadow, radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "at")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(usernameFieldColor)
                            .frame(width: 20)
                        
                        TextField("Optional username", text: $editedUsername)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: editedUsername) { newValue in
                                onUsernameChange(newValue)
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(usernameFieldColor, lineWidth: 1.5)
                )
            }
            
            if !editedUsername.isEmpty && !isValidUsername(editedUsername) {
                Text("Username must be 3-20 characters and contain only letters, numbers, and underscores")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private func modernTextField(title: String, text: Binding<String>, placeholder: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primary)
            
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.card)
                        .shadow(color: AppColors.shadow, radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.accent)
                            .frame(width: 20)
                        
                        TextField(placeholder, text: text)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.accent.opacity(0.3), lineWidth: 1.5)
                )
            }
        }
    }
    
    private var usernameFieldColor: Color {
        if isCheckingUsername {
            return AppColors.accent.opacity(0.6)
        }
        
        if let available = usernameAvailable, !isCheckingUsername {
            return available ? .green.opacity(0.8) : .red.opacity(0.8)
        }
        
        return AppColors.accent.opacity(0.6)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        guard !username.isEmpty else { return true }
        
        return username.count >= 3 && 
               username.count <= 20 &&
               username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
} 