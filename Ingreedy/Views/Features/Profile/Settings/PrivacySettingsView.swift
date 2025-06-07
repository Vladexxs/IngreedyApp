import SwiftUI

/// Modern gizlilik ayarları sayfası
@MainActor
struct PrivacySettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = PrivacySettingsViewModel()
    @EnvironmentObject private var router: Router
    
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
                        
                        // Privacy Settings Content
                        privacySettingsContent
                        
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
            .navigationTitle("Privacy Settings")
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
                viewModel.loadPrivacySettings()
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Privacy & Data")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text("Manage how you share recipes and your app data preferences")
                        .font(.body)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Privacy Settings Content
    
    private var privacySettingsContent: some View {
        VStack(spacing: 16) {
            // Recipe Sharing - Ana özellik
            SettingsGroup(title: "Recipe Sharing") {
                VStack(spacing: 0) {
                    ModernToggleRow(
                        icon: "square.and.arrow.up.fill",
                        title: "Allow Recipe Sharing",
                        subtitle: "Friends can share recipes with you",
                        iconColor: .blue,
                        isOn: $viewModel.allowRecipeSharing
                    )
                }
            }
            
            // App Preferences - Basit ayarlar  
            SettingsGroup(title: "App Preferences") {
                VStack(spacing: 0) {
                    ModernToggleRow(
                        icon: "chart.bar.fill",
                        title: "Analytics",
                        subtitle: "Help improve the app with usage data",
                        iconColor: .orange,
                        isOn: $viewModel.allowAnalytics
                    )
                }
            }
            
            // Data Management - Sadece download
            SettingsGroup(title: "Data Management") {
                VStack(spacing: 0) {
                    ModernSettingsItem(
                        icon: "square.and.arrow.down.fill",
                        title: "Download My Data",
                        subtitle: "Get a copy of your personal data",
                        iconColor: .green,
                        action: { viewModel.downloadPersonalData() }
                    )
                }
            }
        }
    }
}

// MARK: - Modern Toggle Row

struct ModernToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
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
            
            // Toggle
            Toggle("", isOn: $isOn)
                .tint(iconColor)
                .scaleEffect(0.9)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    PrivacySettingsView()
        .environmentObject(Router())
} 