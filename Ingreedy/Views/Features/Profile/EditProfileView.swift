import SwiftUI
import PhotosUI
import Kingfisher

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?
    @State private var editedFullName: String = ""
    @State private var editedUsername: String = ""
    @State private var originalUsername: String = ""
    @State private var isCheckingUsername: Bool = false
    @State private var usernameAvailable: Bool? = nil
    @State private var usernameCheckTask: Task<Void, Never>?
    @State private var isAnimating: Bool = false
    @State private var showingImagePicker: Bool = false
    
    private func cleanURL(from urlString: String) -> URL? {
        guard !urlString.isEmpty else { return nil }
        
        let decoded = urlString.removingPercentEncoding ?? urlString
        guard let encoded = decoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else {
            return URL(string: urlString)
        }
        
        return url
    }
    
    private func handleUsernameChange(_ newValue: String) {
        let trimmedValue = newValue.trimmingCharacters(in: .whitespaces).lowercased()
        
        // Cancel previous task
        usernameCheckTask?.cancel()
        
        // Reset state
        usernameAvailable = nil
        
        // Only check if username is different from original and valid
        if !trimmedValue.isEmpty && trimmedValue != originalUsername.lowercased() && isValidUsername(trimmedValue) {
            usernameCheckTask = Task {
                await checkUsernameAvailability(trimmedValue)
            }
        }
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        guard !username.isEmpty else { return true }
        
        return username.count >= 3 && 
               username.count <= 20 &&
               username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                backgroundView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header Section
                        headerSection
                        
                        // Profile Photo Section
                        EditProfilePhotoSection(
                            viewModel: viewModel,
                            selectedItem: $selectedItem,
                            isAnimating: $isAnimating
                        )
                        
                        // Form Section
                        EditProfileFormSection(
                            editedFullName: $editedFullName,
                            editedUsername: $editedUsername,
                            isCheckingUsername: $isCheckingUsername,
                            usernameAvailable: $usernameAvailable,
                            originalUsername: originalUsername,
                            onUsernameChange: handleUsernameChange
                        )
                        
                        // Save Button
                        saveButtonSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupInitialValues()
                withAnimation(.easeInOut(duration: 0.6)) {
                    isAnimating = true
                }
            }
            .onChange(of: viewModel.user) { _ in
                setupInitialValues()
            }
            .onChange(of: selectedItem) { newItem in
                handleImageSelection(newItem)
            }
        }
    }
}

// MARK: - View Components
private extension EditProfileView {
    
    var backgroundView: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    AppColors.card.opacity(0.3),
                    AppColors.background,
                    AppColors.card.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    var headerSection: some View {
        HStack {
            // Cancel Button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppColors.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.card.opacity(0.8))
                        .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 2)
                )
            }
            
            Spacer()
            
            // Title
            Text("Edit Profile")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primary)
        }
        .padding(.top, 12)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : -10)
    }
    

    

    

    
    var saveButtonSection: some View {
        ModernButton(
            title: "Save Changes",
            action: {
                Task {
                    await saveChanges()
                }
            },
            icon: "checkmark.circle.fill",
            style: .primary,
            isLoading: viewModel.isLoading,
            isDisabled: !canSave
        )
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: isAnimating)
        .shadow(
            color: canSave ? AppColors.accent.opacity(0.3) : Color.clear,
            radius: canSave ? 12 : 0,
            x: 0,
            y: canSave ? 6 : 0
        )
        .animation(.easeInOut(duration: 0.3), value: canSave)
    }
}

// MARK: - Helper Functions
private extension EditProfileView {
    
    func setupInitialValues() {
        if let user = viewModel.user {
            editedFullName = user.fullName
            // Make sure the username field is populated with current username
            let currentUsername = user.username ?? ""
            editedUsername = currentUsername
            originalUsername = currentUsername
        }
    }
    
    func handleImageSelection(_ newItem: PhotosPickerItem?) {
        guard let newItem = newItem else { return }
        
        Task {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.selectedImage = uiImage
                    }
                    
                    viewModel.uploadProfileImage(uiImage)
                }
            }
        }
    }
    

    
    var canSave: Bool {
        guard let user = viewModel.user else { return false }
        
        let hasFullNameChanged = !editedFullName.trimmingCharacters(in: .whitespaces).isEmpty && 
                                user.fullName != editedFullName
        let hasUsernameChanged = editedUsername.trimmingCharacters(in: .whitespaces).lowercased() != originalUsername.lowercased()
        let hasImageChanged = viewModel.selectedImage != nil
        
        if hasUsernameChanged {
            let trimmedUsername = editedUsername.trimmingCharacters(in: .whitespaces)
            return isValidUsername(trimmedUsername) && 
                   (usernameAvailable == true || trimmedUsername.isEmpty) &&
                   !isCheckingUsername
        }
        
        return hasFullNameChanged || hasImageChanged
    }
    

    
    func checkUsernameAvailability(_ username: String) async {
        guard !username.isEmpty else { return }
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCheckingUsername = true
            }
        }
        
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            
            let available = await viewModel.checkUsernameAvailability(username)
            
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCheckingUsername = false
                    usernameAvailable = available
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCheckingUsername = false
                    usernameAvailable = nil
                }
            }
        }
    }
    
    func saveChanges() async {
        guard let user = viewModel.user else { return }
        
        var updatedUser = user
        var hasChanges = false
        
        // Update full name if changed
        let trimmedFullName = editedFullName.trimmingCharacters(in: .whitespaces)
        if !trimmedFullName.isEmpty && user.fullName != trimmedFullName {
            updatedUser.fullName = trimmedFullName
            hasChanges = true
        }
        
        // Update username if changed and valid
        let trimmedUsername = editedUsername.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmedUsername != originalUsername.lowercased() {
            if trimmedUsername.isEmpty {
                updatedUser.username = nil
                hasChanges = true
            } else if isValidUsername(trimmedUsername) && usernameAvailable == true {
                updatedUser.username = trimmedUsername
                hasChanges = true
            }
        }
        
        if hasChanges {
            await withCheckedContinuation { continuation in
                viewModel.saveUser(updatedUser) { error in
                    continuation.resume()
                }
            }
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// Wrapper view for router navigation
struct EditProfileViewWrapper: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isPresented = true
    
    var body: some View {
        EditProfileView(
            viewModel: viewModel, 
            isPresented: Binding(
                get: { isPresented },
                set: { newValue in
                    isPresented = newValue
                    if !newValue {
                        router.navigate(to: .profile)
                    }
                }
            )
        )
        .onAppear {
            viewModel.fetchCurrentUser()
        }
    }
} 
