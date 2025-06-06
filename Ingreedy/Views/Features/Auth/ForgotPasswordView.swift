import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header with close button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.secondary)
                                .frame(width: 32, height: 32)
                                .background(AppColors.card)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 70, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accent, AppColors.accent.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("Forgot Password?")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primary)
                            
                            Text("No worries! Enter your email address and we'll send you a reset link.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Form
                    VStack(spacing: 24) {
                        ModernTextField(
                            title: "Email",
                            placeholder: "Enter your email address",
                            text: $viewModel.forgotPasswordModel.email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            isValid: viewModel.forgotPasswordModel.email.isEmpty ? nil : viewModel.forgotPasswordModel.isValid,
                            errorMessage: viewModel.emailErrorMessage
                        )
                        .onChange(of: viewModel.forgotPasswordModel.email) { _ in
                            viewModel.clearError()
                        }
                        
                        // Reset Button
                        ModernButton(
                            title: "Send Reset Link",
                            action: {
                                viewModel.sendResetEmail()
                            },
                            icon: "paperplane.fill",
                            style: .primary,
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.forgotPasswordModel.isValid
                        )
                    }
                    
                    // Back to Login Link
                    HStack {
                        Text("Remember your password?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.secondary)
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }
            
            // Success Overlay
            if viewModel.resetSuccess {
                SuccessOverlay(
                    title: "Email Sent!",
                    message: viewModel.successMessage,
                    onContinue: {
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }
            
            // Error Overlay
            if let error = viewModel.error {
                VStack {
                    Spacer()
                    ErrorToast(
                        message: error.localizedDescription,
                        onDismiss: {
                            viewModel.clearError()
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.resetSuccess)
        .animation(.easeInOut(duration: 0.3), value: viewModel.error != nil)
    }
}

#Preview {
    ForgotPasswordView()
} 