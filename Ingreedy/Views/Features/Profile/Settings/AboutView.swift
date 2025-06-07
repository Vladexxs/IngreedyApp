import SwiftUI

/// Modern uygulama hakkında sayfası
struct AboutView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background using app colors
                AppColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // App Header Card
                        appHeaderCard
                        
                        // App Information
                        appInfoSection
                        
                        // Features Section
                        featuresSection
                        
                        // Legal & Links
                        legalSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("About Ingreedy")
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
        }
    }
    
    // MARK: - App Header Card
    
    private var appHeaderCard: some View {
        ModernCard {
            VStack(spacing: 20) {
                // App Icon
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.accent)
                
                VStack(spacing: 8) {
                    Text("Ingreedy")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text("Your Ultimate Recipe Companion")
                        .font(.title3)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Version 1.0.0")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AppColors.accent.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - App Information
    
    private var appInfoSection: some View {
        SettingsGroup(title: "About the App") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ingreedy helps you discover amazing recipes based on the ingredients you have at home. Connect with friends and share your favorite dishes.")
                    .font(.body)
                    .foregroundColor(AppColors.secondary)
                    .lineSpacing(2)
            }
            .padding(20)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        SettingsGroup(title: "Key Features") {
            VStack(spacing: 0) {
                FeatureRow(
                    icon: "magnifyingglass.circle.fill",
                    title: "Ingredient-Based Search",
                    description: "Find recipes using ingredients you have",
                    iconColor: .blue
                )
                
                Divider().padding(.horizontal, 20)
                
                FeatureRow(
                    icon: "person.2.circle.fill",
                    title: "Friends & Sharing",
                    description: "Share and discover recipes with friends",
                    iconColor: .green
                )
                
                Divider().padding(.horizontal, 20)
                
                FeatureRow(
                    icon: "heart.circle.fill",
                    title: "Favorites Collection",
                    description: "Save your favorite recipes",
                    iconColor: .pink
                )
            }
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        SettingsGroup(title: "Legal & Support") {
            VStack(spacing: 0) {
                ModernSettingsItem(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    subtitle: "Read our terms and conditions",
                    iconColor: .blue,
                    action: { router.navigate(to: .termsPrivacy) }
                )
                
                Divider().padding(.horizontal, 20)
                
                ModernSettingsItem(
                    icon: "lock.shield.fill",
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    iconColor: .green,
                    action: { router.navigate(to: .termsPrivacy) }
                )
                
                Divider().padding(.horizontal, 20)
                
                ModernSettingsItem(
                    icon: "globe",
                    title: "Visit Our Website",
                    subtitle: "Learn more about Ingreedy",
                    iconColor: AppColors.accent,
                    action: {
                        if let url = URL(string: "https://ingreedy.app") {
                            openURL(url)
                        }
                    }
                )
                
                Divider().padding(.horizontal, 20)
                
                ModernSettingsItem(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    subtitle: "Get help from our team",
                    iconColor: .purple,
                    action: {
                        if let url = URL(string: "mailto:support@ingreedy.com") {
                            openURL(url)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.bold())
                    .foregroundColor(AppColors.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppColors.secondary)
                    .lineSpacing(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview
#Preview {
    AboutView()
        .environmentObject(Router())
} 