import SwiftUI

/// Modern yardım ve destek sayfası
struct HelpSupportView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background using app colors
                AppColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Card
                        headerCard
                        
                        // FAQ Section
                        faqSection
                        
                        // Contact Section
                        contactSection
                        
                        // Feedback Section
                        feedbackSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Help & Support")
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
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.accent)
                
                VStack(spacing: 8) {
                    Text("How can we help?")
                        .font(.title2.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text("Find answers to common questions or get in touch with our support team")
                        .font(.body)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - FAQ Section
    
    private var faqSection: some View {
        SettingsGroup(title: "Frequently Asked Questions") {
            VStack(spacing: 0) {
                FAQItem(
                    question: "How do I add recipes to favorites?",
                    answer: "Tap the heart icon on any recipe to add it to your favorites. You can view all your favorites in your profile."
                )
                
                Divider()
                    .padding(.horizontal, 16)
                
                FAQItem(
                    question: "How do I share recipes with friends?",
                    answer: "Use the share button on any recipe to send it to your friends through the app's sharing feature."
                )
                
                Divider()
                    .padding(.horizontal, 16)
                
                FAQItem(
                    question: "How do I add friends?",
                    answer: "Go to the Friends section and search for users by their username or email address."
                )
            }
        }
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        SettingsGroup(title: "Get Help") {
            VStack(spacing: 0) {
                ModernSettingsItem(
                    icon: "envelope.fill",
                    title: "Email Support",
                    subtitle: "support@ingreedy.com",
                    iconColor: .blue,
                    action: { 
                        if let url = URL(string: "mailto:support@ingreedy.com") {
                            openURL(url)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Feedback Section
    
    private var feedbackSection: some View {
        SettingsGroup(title: "Feedback") {
            VStack(spacing: 0) {
                ModernSettingsItem(
                    icon: "star.fill",
                    title: "Rate the App",
                    subtitle: "Leave a review on the App Store",
                    iconColor: .yellow,
                    action: { /* Open App Store rating */ }
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                ModernSettingsItem(
                    icon: "exclamationmark.triangle.fill",
                    title: "Report a Problem",
                    subtitle: "Tell us about any issues",
                    iconColor: .red,
                    action: { 
                        if let url = URL(string: "mailto:support@ingreedy.com?subject=Problem Report") {
                            openURL(url)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Modern FAQ Item

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) { 
                    isExpanded.toggle() 
                } 
            }) {
                HStack(spacing: 12) {
                    Text(question)
                        .font(.body.bold())
                        .foregroundColor(AppColors.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(AppColors.accent)
                        .font(.title3)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle()
                        .fill(AppColors.accent.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                    
                    Text(answer)
                        .font(.body)
                        .foregroundColor(AppColors.secondary)
                        .lineSpacing(2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
    }
}

#Preview {
    HelpSupportView()
        .environmentObject(Router())
} 