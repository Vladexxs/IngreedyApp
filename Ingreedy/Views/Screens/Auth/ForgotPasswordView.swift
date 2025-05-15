import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @StateObject private var viewModel = LoginViewModel()
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Forgot Password")
                    .font(.largeTitle.bold())
                    .foregroundColor(AppColors.text)
                Text("Enter your registered email address. A password reset link will be sent to your email.")
                    .font(.body)
                    .foregroundColor(AppColors.text)
                    .multilineTextAlignment(.center)
                
                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(AppColors.card)
                    .cornerRadius(10)
                    .foregroundColor(AppColors.text)
                    .onChange(of: email) { _ in
                        viewModel.clearError()
                    }
                
                Button(action: {
                    Task { await sendReset() }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Send")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.accent)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.isLoading)
                
                Spacer()
            }
            .padding()
            .alert("Success", isPresented: $showSuccess, actions: {
                Button("OK", role: .cancel, action: { dismiss() })
            }, message: {
                Text("A password reset link has been sent to your email address.")
            })
            
            if let error = viewModel.error {
                ErrorView(
                    error: error,
                    retryAction: nil,
                    dismissAction: {
                        viewModel.clearError()
                    }
                )
            }
        }
    }
    
    func sendReset() async {
        // Cleaned email
        let cleanedEmail = email.normalizedEmail
        
        guard !cleanedEmail.isEmpty else {
            viewModel.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address."])
            return
        }
        guard cleanedEmail.isValidEmail else {
            viewModel.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address."])
            return
        }
        
        // Send password reset request
        await viewModel.resetPassword(email: cleanedEmail)
        
        // If there's no error after reset attempt, show success
        if viewModel.error == nil {
            showSuccess = true
        }
    }
}

#Preview {
    ForgotPasswordView()
} 