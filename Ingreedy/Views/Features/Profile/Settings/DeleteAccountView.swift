import SwiftUI

/// Modern hesap silme sayfası
@MainActor
struct DeleteAccountView: View {
    // MARK: - Properties
    @StateObject private var viewModel = DeleteAccountViewModel()
    @EnvironmentObject private var router: Router
    @State private var confirmationText = ""
    @State private var showFinalConfirmation = false
    @State private var agreedToTerms = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background using app colors
                AppColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Warning Header Card
                        warningHeaderCard
                        
                        // Data Export Reminder
                        dataExportCard
                        
                        // What Will Be Deleted
                        deletionInfoCard
                        
                        // Confirmation Section
                        confirmationCard
                        
                        // Delete Button
                        deleteButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    ModernLoadingOverlay()
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.accent, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton {
                        router.navigate(to: .modernSettings)
                    }
                }
            }
            .alert("Final Confirmation", isPresented: $showFinalConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Forever", role: .destructive) {
                    viewModel.deleteAccount()
                }
            } message: {
                Text("Are you absolutely sure? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
                Button("Try Again") {
                    viewModel.deleteAccount()
                }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: viewModel.isAccountDeleted) { isDeleted in
                if isDeleted {
                    router.navigate(to: .login)
                }
            }
            .onReceive(viewModel.$error) { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Warning Header Card
    
    private var warningHeaderCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                VStack(spacing: 8) {
                    Text("Delete Account")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text("This action is permanent and cannot be undone. All your data will be permanently deleted.")
                        .font(.body)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Data Export Card
    
    private var dataExportCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.accent)
                    
                    Text("Before You Delete")
                        .font(.headline.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                }
                
                Text("Consider downloading your data from Account Settings before proceeding. This includes your profile, favorites, and activity history.")
                    .font(.body)
                    .foregroundColor(AppColors.secondary)
                    .lineSpacing(2)
                
                Button(action: { viewModel.exportDataBeforeDeletion() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.body.bold())
                        Text("Export My Data First")
                            .font(.body.bold())
                    }
                    .foregroundColor(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
        }
    }
    
    // MARK: - Deletion Info Card
    
    private var deletionInfoCard: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("What will be deleted:")
                    .font(.headline.bold())
                    .foregroundColor(AppColors.primary)
                
                VStack(spacing: 12) {
                    DeletionItem(text: "Your profile and account information")
                    DeletionItem(text: "All your favorite recipes")
                    DeletionItem(text: "Your friends and connections")
                    DeletionItem(text: "All app data and preferences")
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Confirmation Card
    
    private var confirmationCard: some View {
        ModernCard {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Confirmation Required")
                        .font(.headline.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text("To confirm deletion, type \"DELETE\" below:")
                        .font(.body)
                        .foregroundColor(AppColors.secondary)
                    
                    TextField("Type DELETE", text: $confirmationText)
                        .font(.body.bold())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                
                HStack(spacing: 12) {
                    Toggle("", isOn: $agreedToTerms)
                        .tint(.red)
                        .scaleEffect(0.9)
                    
                    Text("I understand this action is permanent and cannot be undone")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                    
                    Spacer()
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button(action: { showFinalConfirmation = true }) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                    .font(.body.bold())
                Text("Delete My Account Forever")
                    .font(.body.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isDeleteEnabled ? Color.red : Color.gray)
            .cornerRadius(12)
            .shadow(color: isDeleteEnabled ? Color.red.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isDeleteEnabled)
        .scaleEffect(isDeleteEnabled ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isDeleteEnabled)
    }
    
    // MARK: - Computed Properties
    
    private var isDeleteEnabled: Bool {
        confirmationText.uppercased() == "DELETE" && agreedToTerms
    }
}

// MARK: - Supporting Views

struct DeletionItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .font(.body)
                .foregroundColor(.red)
            
            Text(text)
                .font(.body)
                .foregroundColor(AppColors.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    DeleteAccountView()
        .environmentObject(Router())
} 