import SwiftUI

struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let icon: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    
    @State private var isEditing = false
    @State private var isPasswordVisible = false
    
    var isValid: Bool?
    var errorMessage: String?
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        icon: String,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isValid: Bool? = nil,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.icon = icon
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Field Container
            VStack(spacing: 0) {
                HStack {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 24)
                    
                    // Input Field
                    VStack(alignment: .leading, spacing: 2) {
                        // Floating Label
                        if !text.isEmpty || isEditing {
                            Text(title)
                                .font(.caption)
                                .foregroundColor(labelColor)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Text Input
                        HStack {
                            if isSecure && !isPasswordVisible {
                                ZStack(alignment: .leading) {
                                    // Custom placeholder
                                    if text.isEmpty && !floatingTitle {
                                        Text(placeholder)
                                            .foregroundColor(AppColors.secondary.opacity(0.7))
                                            .font(.body)
                                    }
                                    
                                    SecureField("", text: $text)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .keyboardType(keyboardType)
                                        .textContentType(textContentType)
                                        .foregroundColor(AppColors.text)
                                        .accentColor(AppColors.accent)
                                }
                            } else {
                                ZStack(alignment: .leading) {
                                    // Custom placeholder
                                    if text.isEmpty && !floatingTitle {
                                        Text(placeholder)
                                            .foregroundColor(AppColors.secondary.opacity(0.7))
                                            .font(.body)
                                    }
                                    
                                    TextField("", text: $text)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .keyboardType(keyboardType)
                                        .textContentType(textContentType)
                                        .autocapitalization(shouldDisableCapitalization ? .none : .words)
                                        .autocorrectionDisabled(shouldDisableCorrection)
                                        .foregroundColor(AppColors.text)
                                        .accentColor(AppColors.accent)
                                }
                            }
                            
                            // Password visibility toggle
                            if isSecure {
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppColors.secondary)
                                }
                            }
                            
                            // Validation icon
                            if let isValid = isValid {
                                Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(isValid ? .green : .red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, floatingTitle ? 16 : 12)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .scaleEffect(isEditing ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isEditing)
            }
            
            // Error Message
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = true
            }
        }
        .onChange(of: text) { _ in
            if !isEditing {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditing = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var floatingTitle: Bool {
        !text.isEmpty || isEditing
    }
    
    private var iconColor: Color {
        if let isValid = isValid {
            return isValid ? .green : .red
        }
        return isEditing ? AppColors.accent : AppColors.secondary
    }
    
    private var labelColor: Color {
        if let isValid = isValid {
            return isValid ? .green : .red
        }
        return isEditing ? AppColors.accent : AppColors.secondary
    }
    
    private var borderColor: Color {
        if let isValid = isValid {
            return isValid ? .green.opacity(0.6) : .red.opacity(0.6)
        }
        return isEditing ? AppColors.accent.opacity(0.8) : AppColors.secondary.opacity(0.3)
    }
    
    private var borderWidth: CGFloat {
        isEditing ? 2 : 1
    }
    
    private var backgroundColor: Color {
        isEditing ? AppColors.card.opacity(0.8) : AppColors.card.opacity(0.6)
    }
    
    // Auto-capitalization should be disabled for email, username, and password fields
    private var shouldDisableCapitalization: Bool {
        return keyboardType == .emailAddress ||
               textContentType == .emailAddress ||
               textContentType == .username ||
               textContentType == .password ||
               textContentType == .newPassword
    }
    
    // Auto-correction should be disabled for email, username, and password fields
    private var shouldDisableCorrection: Bool {
        return keyboardType == .emailAddress ||
               textContentType == .emailAddress ||
               textContentType == .username ||
               textContentType == .password ||
               textContentType == .newPassword
    }
} 