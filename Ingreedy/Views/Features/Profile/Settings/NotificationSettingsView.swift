import SwiftUI
import UserNotifications

/// Modern bildirim ayarları sayfası
@MainActor
struct NotificationSettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @EnvironmentObject private var router: Router
    @Environment(\.openURL) private var openURL
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background using app colors
                AppColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Card
                        headerCard
                        
                        // Notification Settings Content
                        notificationSettingsContent
                        
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
            .navigationTitle("Notifications")
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
                viewModel.loadNotificationSettings()
            }
            .onChange(of: viewModel.shouldOpenSettings) { shouldOpen in
                if shouldOpen {
                    openSystemSettings()
                    viewModel.shouldOpenSettings = false
                }
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                VStack(spacing: 8) {
                    Text("Notifications")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text("Stay updated with friend activities and app updates")
                        .font(.body)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Notification Settings Content
    
    private var notificationSettingsContent: some View {
        VStack(spacing: 16) {
            // Push Notifications
            SettingsGroup(title: "Push Notifications") {
                if viewModel.notificationsEnabled {
                    VStack(spacing: 0) {
                        ModernToggleRow(
                            icon: "person.2.fill",
                            title: "Friend Activities",
                            subtitle: "When friends share recipes with you",
                            iconColor: .green,
                            isOn: $viewModel.friendActivities
                        )
                        
                        Divider().padding(.horizontal, 20)
                        
                        ModernToggleRow(
                            icon: "bell.badge.fill",
                            title: "App Updates",
                            subtitle: "New features and important updates",
                            iconColor: AppColors.accent,
                            isOn: $viewModel.appUpdates
                        )
                    }
                } else {
                    NotificationPermissionCard(
                        onEnablePressed: {
                            viewModel.requestNotificationPermission()
                        }
                    )
                }
            }
            
            // Email Notifications  
            SettingsGroup(title: "Email Notifications") {
                VStack(spacing: 0) {
                    ModernToggleRow(
                        icon: "envelope.fill",
                        title: "Weekly Recipe Digest",
                        subtitle: "Get trending recipes delivered weekly",
                        iconColor: .purple,
                        isOn: $viewModel.weeklyDigest
                    )
                }
            }
            
            // Settings Management
            SettingsGroup(title: "Notification Management") {
                VStack(spacing: 0) {
                    ModernSettingsItem(
                        icon: "gear.badge",
                        title: "System Settings",
                        subtitle: "Open iOS notification settings",
                        iconColor: .gray,
                        action: { viewModel.openSystemSettings() }
                    )
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            openURL(settingsUrl)
        }
    }
}

// MARK: - Supporting Views

struct NotificationPermissionCard: View {
    let onEnablePressed: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.secondary)
            
            VStack(spacing: 8) {
                Text("Notifications Disabled")
                    .font(.title3.bold())
                    .foregroundColor(AppColors.primary)
                
                Text("Enable notifications to stay updated with recipe recommendations and friend activities.")
                    .font(.body)
                    .foregroundColor(AppColors.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button(action: onEnablePressed) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.body.bold())
                    Text("Enable Notifications")
                        .font(.body.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.accent)
                .cornerRadius(12)
            }
        }
        .padding(24)
    }
}

// MARK: - Preview
#Preview {
    NotificationSettingsView()
        .environmentObject(Router())
} 