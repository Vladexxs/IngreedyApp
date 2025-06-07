import SwiftUI

/// Modern hesap ayarları sayfası
@MainActor
struct AccountSettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = AccountSettingsViewModel()
    @EnvironmentObject private var router: Router
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background using app colors
                AppColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Info Card
                        if let user = viewModel.currentUser {
                            profileInfoCard(user: user)
                        }
                        
                        // Account Settings Groups
                        accountSettingsContent
                        
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
            .navigationTitle("Account Settings")
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
            .onAppear {
                viewModel.loadCurrentUser()
            }
        }
    }
    
    // MARK: - Profile Info Card
    
    private func profileInfoCard(user: User) -> some View {
        ModernCard {
            VStack(spacing: 20) {
                // Profile Picture and Status Section
                HStack {
                    AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.8), AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay(
                            Text(userInitials(from: user.fullName))
                                .font(.title.bold())
                                .foregroundColor(.white)
                        )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.accent.opacity(0.3), lineWidth: 2)
                    )
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Account Status")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.secondary)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Active")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // User Info - Simplified to just show data without edit buttons
                VStack(spacing: 12) {
                    InfoRow(
                        icon: "person.fill",
                        title: "Display Name",
                        value: user.fullName,
                        isEditable: false
                    )
                    
                    InfoRow(
                        icon: "at",
                        title: "Username",
                        value: user.username ?? "Not set",
                        isEditable: false
                    )
                    
                    InfoRow(
                        icon: "envelope.fill",
                        title: "Email",
                        value: user.email,
                        isEditable: false
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Account Settings Content
    
    private var accountSettingsContent: some View {
        VStack(spacing: 16) {
            // Profile Management
            SettingsGroup(title: "Profile") {
                VStack(spacing: 0) {
                    ModernSettingsItem(
                        icon: "person.fill",
                        title: "Edit Profile",
                        subtitle: "Update name, username and photo",
                        iconColor: AppColors.accent,
                        action: { router.navigate(to: .editProfile) }
                    )
                }
            }
            
            // Account Information
            SettingsGroup(title: "Account Information") {
                VStack(spacing: 0) {
                    ModernSettingsItem(
                        icon: "envelope.fill",
                        title: "Email Address",
                        subtitle: viewModel.currentUser?.email ?? "Not set",
                        iconColor: .blue,
                        action: { /* Could show email change options in future */ }
                    )
                    
                    Divider().padding(.horizontal, 20)
                    
                    ModernSettingsItem(
                        icon: "calendar",
                        title: "Account Created",
                        subtitle: formatAccountCreatedDate(),
                        iconColor: .green,
                        action: { /* Just informational */ }
                    )
                }
            }
            
            // Security  
            SettingsGroup(title: "Security") {
                VStack(spacing: 0) {
                    ModernSettingsItem(
                        icon: "key.fill",
                        title: "Change Password",
                        subtitle: "Update your password",
                        iconColor: .orange,
                        action: { showChangePasswordAlert() }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func userInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    private func formatAccountCreatedDate() -> String {
        guard let user = viewModel.currentUser,
              let createdAt = user.createdAt else {
            return "Unknown"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    private func showChangePasswordAlert() {
        // Simple alert for password change
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let isEditable: Bool
    
    init(icon: String, title: String, value: String, isEditable: Bool = false) {
        self.icon = icon
        self.title = title
        self.value = value
        self.isEditable = isEditable
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(AppColors.secondary)
                
                Text(value)
                    .font(.body.bold())
                    .foregroundColor(AppColors.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ModernSettingsItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.bold())
                        .foregroundColor(AppColors.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.secondary.opacity(0.5))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                    .scaleEffect(1.2)
                
                Text("Loading...")
                    .font(.body.bold())
                    .foregroundColor(AppColors.primary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 8)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    AccountSettingsView()
        .environmentObject(Router())
} 