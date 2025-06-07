import SwiftUI

/// Modern Settings ana sayfası
@MainActor
struct ModernSettingsView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background using app colors
                AppColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Header Card
                        profileHeaderCard
                        
                        // Settings Groups
                        settingsContent
                        
                        // Sign Out Section
                        signOutSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.accent, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton {
                        router.navigate(to: .profile)
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onChange(of: viewModel.shouldNavigateToLogin) { shouldNavigate in
                if shouldNavigate {
                    router.navigate(to: .login)
                }
            }
        }
    }
    
    // MARK: - Profile Header Card
    
    private var profileHeaderCard: some View {
        ModernCard {
            HStack(spacing: 16) {
                // Profile Avatar
                Button(action: { router.navigate(to: .accountSettings) }) {
                    AsyncImage(url: URL(string: viewModel.userProfileImageUrl ?? "")) { image in
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
                            Text(viewModel.userInitials)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.accent.opacity(0.3), lineWidth: 2)
                    )
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userDisplayName)
                        .font(.title3.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text(viewModel.userEmail)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondary)
                    
                    if let username = viewModel.username {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundColor(AppColors.accent)
                    }
                }
                
                Spacer()
                
                // Edit Button
                Button(action: { router.navigate(to: .editProfile) }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Settings Content
    
    private var settingsContent: some View {
        VStack(spacing: 16) {
            // Account & Profile
            SettingsGroup(title: "Account & Profile") {
                SettingsItem(
                    icon: "person.circle.fill",
                    title: "Edit Profile",
                    subtitle: "Update name, username and photo",
                    iconColor: AppColors.accent,
                    action: { router.navigate(to: .editProfile) }
                )
                
                SettingsItem(
                    icon: "lock.shield.fill",
                    title: "Privacy & Security",
                    subtitle: "Profile visibility, data controls",
                    iconColor: .blue,
                    action: { router.navigate(to: .privacySettings) }
                )
            }
            
            // Preferences
            SettingsGroup(title: "Preferences") {
                SettingsItem(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    subtitle: "Push notifications, email alerts",
                    iconColor: .red,
                    action: { router.navigate(to: .notificationSettings) }
                )
                
                SettingsItem(
                    icon: "heart.fill",
                    title: "Recipe Preferences",
                    subtitle: "Dietary restrictions, favorites",
                    iconColor: .pink,
                    action: { /* TODO: Recipe preferences */ }
                )
            }
            
            // Support & About
            SettingsGroup(title: "Support & About") {
                SettingsItem(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "FAQ, contact support",
                    iconColor: .green,
                    action: { router.navigate(to: .helpSupport) }
                )
                
                SettingsItem(
                    icon: "info.circle.fill",
                    title: "About Ingreedy",
                    subtitle: "Version, legal, credits",
                    iconColor: .purple,
                    action: { router.navigate(to: .about) }
                )
            }
            
            // Data & Storage
            SettingsGroup(title: "Data & Storage") {
                SettingsItem(
                    icon: "externaldrive.fill",
                    title: "Storage & Data",
                    subtitle: "Cache, downloads, exports",
                    iconColor: .orange,
                    action: { /* TODO: Storage settings */ }
                )
                
                SettingsItem(
                    icon: "trash.fill",
                    title: "Delete Account",
                    subtitle: "Permanently remove account",
                    iconColor: .red,
                    action: { router.navigate(to: .deleteAccount) }
                )
            }
        }
    }
    
    // MARK: - Sign Out Section
    
    private var signOutSection: some View {
        ModernCard {
            Button(action: { showingSignOutAlert = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                    
                    Text("Sign Out")
                        .font(.body.bold())
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Supporting Components

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundColor(AppColors.secondary)
                .padding(.horizontal, 4)
            
            ModernCard {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct SettingsItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                // Content
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
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(AppColors.secondary.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.001)) // Invisible but tappable
        )
    }
}

struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
            )
    }
}

struct ModernBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                Text("Back")
                    .font(.body.weight(.medium))
            }
            .foregroundColor(.white)
        }
    }
}

// MARK: - Settings ViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userDisplayName: String = "User"
    @Published var userEmail: String = "user@example.com"
    @Published var username: String? = nil
    @Published var userProfileImageUrl: String? = nil
    @Published var shouldNavigateToLogin = false
    
    private let authService = FirebaseAuthenticationService.shared
    
    init() {
        loadUserData()
    }
    
    var userInitials: String {
        let components = userDisplayName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    private func loadUserData() {
        if let user = authService.currentUser {
            userDisplayName = user.fullName.isEmpty ? "User" : user.fullName
            userEmail = user.email
            username = user.username
            userProfileImageUrl = user.profileImageUrl
        }
    }
    
    func signOut() {
        do {
            try authService.logout()
            shouldNavigateToLogin = true
        } catch {
            print("Sign out error: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    ModernSettingsView()
        .environmentObject(Router())
} 