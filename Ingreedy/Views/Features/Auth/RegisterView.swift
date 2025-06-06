import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    
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
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
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
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primary)
                            
                            Text("Join our community today")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Form
                    VStack(spacing: 20) {
                        ModernTextField(
                            title: "Full Name",
                            placeholder: "Enter your full name",
                            text: $viewModel.registerModel.fullName,
                            icon: "person.fill",
                            textContentType: .name,
                            isValid: viewModel.registerModel.fullName.isEmpty ? nil : viewModel.registerModel.isFullNameValid,
                            errorMessage: viewModel.fullNameErrorMessage
                        )
                        .onChange(of: viewModel.registerModel.fullName) { _ in
                            viewModel.clearError()
                        }
                        
                        ModernTextField(
                            title: "Username",
                            placeholder: "Choose a unique username",
                            text: $viewModel.registerModel.username,
                            icon: "at",
                            textContentType: .username,
                            isValid: usernameValidationState,
                            errorMessage: viewModel.usernameErrorMessage
                        )
                        .onChange(of: viewModel.registerModel.username) { _ in
                            viewModel.clearError()
                        }
                        
                        ModernTextField(
                            title: "Email",
                            placeholder: "Enter your email address",
                            text: $viewModel.registerModel.email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            isValid: viewModel.registerModel.email.isEmpty ? nil : viewModel.registerModel.isEmailValid,
                            errorMessage: viewModel.emailErrorMessage
                        )
                        .onChange(of: viewModel.registerModel.email) { _ in
                            viewModel.clearError()
                        }
                        
                        ModernTextField(
                            title: "Password",
                            placeholder: "Create a strong password",
                            text: $viewModel.registerModel.password,
                            isSecure: true,
                            icon: "lock.fill",
                            textContentType: .newPassword,
                            isValid: viewModel.registerModel.password.isEmpty ? nil : viewModel.registerModel.isPasswordValid,
                            errorMessage: viewModel.passwordErrorMessage
                        )
                        .onChange(of: viewModel.registerModel.password) { _ in
                            viewModel.clearError()
                        }
                        
                        ModernTextField(
                            title: "Confirm Password",
                            placeholder: "Confirm your password",
                            text: $viewModel.registerModel.confirmPassword,
                            isSecure: true,
                            icon: "lock.fill",
                            textContentType: .newPassword,
                            isValid: viewModel.registerModel.confirmPassword.isEmpty ? nil : (viewModel.registerModel.password == viewModel.registerModel.confirmPassword),
                            errorMessage: viewModel.confirmPasswordErrorMessage
                        )
                        .onChange(of: viewModel.registerModel.confirmPassword) { _ in
                            viewModel.clearError()
                        }
                    }
                    
                    // Action Button
                    VStack(spacing: 16) {
                        ModernButton(
                            title: "Create Account",
                            action: {
                                viewModel.register()
                            },
                            icon: "person.badge.plus.fill",
                            style: .primary,
                            isLoading: viewModel.isLoading,
                            isDisabled: !canRegister
                        )
                        
                        // Sign In Link
                        HStack {
                            Text("Already have an account?")
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
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            
            // Success Overlay
            if viewModel.registrationSuccess {
                SuccessOverlay(
                    title: "Account Created!",
                    message: "Welcome to Ingreedy! You can now start exploring recipes.",
                    onContinue: {
                        dismiss()
                        router.navigate(to: .home)
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
        .animation(.easeInOut(duration: 0.3), value: viewModel.registrationSuccess)
        .animation(.easeInOut(duration: 0.3), value: viewModel.error != nil)
    }
    
    // MARK: - Computed Properties
    
    private var usernameValidationState: Bool? {
        guard !viewModel.registerModel.username.isEmpty else { return nil }
        
        if viewModel.isUsernameChecking {
            return nil
        }
        
        if !viewModel.registerModel.isUsernameValid {
            return false
        }
        
        return viewModel.isUsernameAvailable
    }
    
    private var canRegister: Bool {
        guard viewModel.registerModel.isValid else { return false }
        guard viewModel.isUsernameAvailable == true else { return false }
        guard !viewModel.isUsernameChecking else { return false }
        return true
    }
}

// Success Overlay Component
struct SuccessOverlay: View {
    let title: String
    let message: String
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primary)
                    
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                }
                
                ModernButton(
                    title: "Continue",
                    action: onContinue,
                    icon: "arrow.right",
                    style: .primary
                )
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.background)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(Router())
} 