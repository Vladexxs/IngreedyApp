import SwiftUI

/// Şartlar ve gizlilik sayfası
struct TermsPrivacyView: View {
    @EnvironmentObject private var router: Router
    @State private var selectedTab: DocumentTab = .terms
    
    enum DocumentTab: CaseIterable {
        case terms, privacy
        
        var title: String {
            switch self {
            case .terms: return "Terms of Service"
            case .privacy: return "Privacy Policy"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        ForEach(DocumentTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Text(tab.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedTab == tab ? AppColors.accent : AppColors.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedTab == tab ? AppColors.accent.opacity(0.1) : Color.clear
                                    )
                                    .overlay(
                                        Rectangle()
                                            .fill(AppColors.accent)
                                            .frame(height: 2)
                                            .opacity(selectedTab == tab ? 1 : 0),
                                        alignment: .bottom
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .background(AppColors.card)
                    
                    // Document Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if selectedTab == .terms {
                                termsContent
                            } else {
                                privacyContent
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        router.navigate(to: .profile)
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DocumentSection(title: "1. Acceptance of Terms") {
                Text("By downloading, installing, or using the Ingreedy application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.")
            }
            
            DocumentSection(title: "2. Use of Service") {
                Text("Ingreedy provides a platform for discovering, sharing, and organizing recipes. You may use our service for personal, non-commercial purposes in accordance with these terms.")
            }
            
            DocumentSection(title: "3. User Accounts") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• You are responsible for maintaining the confidentiality of your account")
                    Text("• You must provide accurate and complete information")
                    Text("• You are responsible for all activities under your account")
                    Text("• You must notify us immediately of any unauthorized access")
                }
            }
            
            DocumentSection(title: "4. Content Guidelines") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When sharing recipes or content, you agree not to:")
                    Text("• Share copyrighted content without permission")
                    Text("• Post harmful, offensive, or inappropriate content")
                    Text("• Violate any applicable laws or regulations")
                    Text("• Spam or abuse other users")
                }
            }
            
            DocumentSection(title: "5. Intellectual Property") {
                Text("All content in the app, including recipes, images, and text, are protected by intellectual property laws. Users retain rights to their original recipes but grant Ingreedy a license to use and display them.")
            }
            
            DocumentSection(title: "6. Disclaimers") {
                Text("Ingreedy is provided 'as is' without warranties. We are not responsible for the accuracy of recipes or any dietary restrictions. Always verify ingredients and cooking instructions.")
            }
            
            Text("Last updated: December 2024")
                .font(.caption)
                .foregroundColor(AppColors.secondary)
                .padding(.top)
        }
    }
    
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DocumentSection(title: "1. Information We Collect") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("We collect information you provide directly:")
                    Text("• Account information (email, name, username)")
                    Text("• Recipe data and preferences")
                    Text("• Profile information and photos")
                    Text("• Usage analytics and app interactions")
                }
            }
            
            DocumentSection(title: "2. How We Use Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your information is used to:")
                    Text("• Provide and improve our services")
                    Text("• Personalize your recipe recommendations")
                    Text("• Enable social features and sharing")
                    Text("• Send notifications (with your consent)")
                    Text("• Ensure security and prevent abuse")
                }
            }
            
            DocumentSection(title: "3. Information Sharing") {
                Text("We do not sell your personal information. We may share data with service providers, for legal compliance, or with your consent for social features within the app.")
            }
            
            DocumentSection(title: "4. Data Security") {
                Text("We implement industry-standard security measures to protect your data. However, no method of transmission over the internet is 100% secure.")
            }
            
            DocumentSection(title: "5. Your Rights") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You have the right to:")
                    Text("• Access and update your information")
                    Text("• Delete your account and data")
                    Text("• Control notification preferences")
                    Text("• Export your data")
                    Text("• Object to certain data processing")
                }
            }
            
            DocumentSection(title: "6. Cookies and Tracking") {
                Text("We use cookies and similar technologies to improve your experience, analyze usage, and provide personalized content. You can manage these preferences in your device settings.")
            }
            
            DocumentSection(title: "7. Children's Privacy") {
                Text("Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13.")
            }
            
            DocumentSection(title: "8. Contact Us") {
                Text("For privacy-related questions, contact us at privacy@ingreedy.com or through the app's support section.")
            }
            
            Text("Last updated: December 2024")
                .font(.caption)
                .foregroundColor(AppColors.secondary)
                .padding(.top)
        }
    }
}

struct DocumentSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primary)
            
            content
                .font(.body)
                .foregroundColor(AppColors.secondary)
                .lineSpacing(2)
        }
    }
}

#Preview {
    TermsPrivacyView()
        .environmentObject(Router())
} 