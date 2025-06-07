import SwiftUI

struct SetupUsernameView: View {
    @StateObject private var viewModel = SetupUsernameViewModel()
    @EnvironmentObject private var router: Router
    @State private var username: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // App-consistent Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.primary,
                    AppColors.primary.opacity(0.8),
                    AppColors.accent.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating Circles with App Colors
            GeometryReader { geometry in
                Circle()
                    .fill(AppColors.card.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.7)
                
                Circle()
                    .fill(AppColors.background.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.8)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Header Section
                    headerSection
                    
                    // Main Content Card
                    mainContentCard
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(viewModel.$error) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Animated Icon with App Colors
            ZStack {
                Circle()
                    .fill(AppColors.card.opacity(0.4))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(AppColors.accent.opacity(0.3))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.badge.plus.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(AppColors.buttonText)
            }
            .shadow(color: AppColors.shadow, radius: 15, x: 0, y: 8)
            
            VStack(spacing: 8) {
                Text("Welcome to Ingreedy!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.buttonText)
                    .multilineTextAlignment(.center)
                
                Text("Complete your profile setup by choosing a unique username")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.buttonText.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Main Content Card
    private var mainContentCard: some View {
        VStack(spacing: 32) {
            // Username Input Section
            usernameInputSection
            
            // Continue Button
            continueButton
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.background)
                .shadow(color: AppColors.shadow, radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Username Input Section
    private var usernameInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            HStack {
                Image(systemName: "at.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.accent)
                
                Text("Choose Your Username")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }
            
            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "at")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isTextFieldFocused ? AppColors.accent : AppColors.secondary)
                        .frame(width: 20)
                    
                    TextField("username", text: $username)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.text)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isTextFieldFocused)
                        .onChange(of: username) { _ in
                            viewModel.clearError()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.card.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isTextFieldFocused ? AppColors.accent : AppColors.secondary.opacity(0.3),
                                    lineWidth: isTextFieldFocused ? 2 : 1
                                )
                        )
                )
                
                // Error Message
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 4)
                }
                
                // Username Requirements
                VStack(alignment: .leading, spacing: 4) {
                    requirementRow(
                        text: "At least 3 characters long",
                        isValid: username.count >= 3
                    )
                    
                    requirementRow(
                        text: "Only letters, numbers, and underscores",
                        isValid: username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
                    )
                    
                    requirementRow(
                        text: "No spaces allowed",
                        isValid: !username.contains(" ")
                    )
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Requirement Row
    private func requirementRow(text: String, isValid: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isValid ? .green : AppColors.secondary)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isValid ? .green : AppColors.secondary)
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: {
            Task {
                await viewModel.setupUsername(username)
                if viewModel.isSetupComplete {
                    router.navigate(to: .home)
                }
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.buttonText))
                        .scaleEffect(0.9)
                } else {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(AppColors.buttonText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isValidUsername ?
                        LinearGradient(
                            colors: [AppColors.accent, AppColors.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [AppColors.secondary.opacity(0.4), AppColors.secondary.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(
                color: isValidUsername ? AppColors.accent.opacity(0.4) : Color.clear,
                radius: isValidUsername ? 8 : 0,
                x: 0,
                y: 4
            )
            .disabled(!isValidUsername || viewModel.isLoading)
            .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Validation
    private var isValidUsername: Bool {
        return username.count >= 3 &&
               username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" } &&
               !username.trimmingCharacters(in: .whitespaces).isEmpty &&
               !username.contains(" ")
    }
}

#Preview {
    SetupUsernameView()
        .environmentObject(Router())
} 