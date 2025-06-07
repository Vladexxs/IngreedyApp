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
                        profilePhotoSection
                        
                        // Form Section
                        formSection
                        
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
    
    var profilePhotoSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Profile Image Container
                profileImageContainer
                
                // Photo Picker Button
                photoPickerButton
            }
            .scaleEffect(isAnimating ? 1 : 0.8)
            .opacity(isAnimating ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isAnimating)
            
            // Change Photo Text
            Text("Tap to change photo")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.secondary)
                .opacity(isAnimating ? 0.8 : 0)
                .animation(.easeInOut(duration: 0.5).delay(0.3), value: isAnimating)
        }
    }
    
    var profileImageContainer: some View {
        ZStack {
            // Shadow circle
            Circle()
                .fill(AppColors.shadow)
                .frame(width: 140, height: 140)
                .offset(x: 2, y: 4)
            
            // Main image circle
            profileImageView
                .frame(width: 135, height: 135)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [AppColors.accent.opacity(0.6), AppColors.primary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
        }
    }
    
    var photoPickerButton: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 44, height: 44)
                    .shadow(color: AppColors.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .offset(x: 45, y: 40)
        }
    }
    
    var formSection: some View {
        VStack(spacing: 24) {
            // Full Name Field
            modernTextField(
                title: "Full Name",
                text: $editedFullName,
                placeholder: "Enter your full name",
                icon: "person.fill",
                keyboardType: .default
            )
            .opacity(isAnimating ? 1 : 0)
            .offset(x: isAnimating ? 0 : -20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isAnimating)
            
            // Username Field
            modernUsernameField
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isAnimating)
            
            // Email Field (Read-only)
            if let user = viewModel.user {
                modernReadOnlyField(
                    title: "Email",
                    text: user.email,
                    icon: "envelope.fill"
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(x: isAnimating ? 0 : -20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isAnimating)
            }
        }
    }
    
    var modernUsernameField: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Field Label
            HStack(spacing: 8) {
                Image(systemName: "at")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                
                Text("Username")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                // Optional badge
                Text("Optional")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColors.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.secondary.opacity(0.1))
                    )
            }
            
            // Input Container
            HStack(spacing: 12) {
                // Text Field
                TextField(originalUsername.isEmpty ? "@username" : "@\(originalUsername)", text: $editedUsername)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.55, green: 0.4, blue: 0.3)) // Brown tone for better readability
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onAppear {
                        // Ensure username is loaded when field appears
                        if editedUsername.isEmpty && !originalUsername.isEmpty {
                            editedUsername = originalUsername
                        }
                    }
                    .onChange(of: editedUsername) { newValue in
                        handleUsernameChange(newValue)
                    }
                
                // Status Indicator
                usernameStatusIndicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.background)
                    .stroke(usernameFieldBorderColor, lineWidth: 2)
                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
            )
            
            // Helper text
            if editedUsername.isEmpty && originalUsername.isEmpty {
                Text("You can set a unique username that others can use to find you")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.secondary)
                    .padding(.horizontal, 4)
            }
            
            // Validation Message
            if !editedUsername.isEmpty {
                usernameValidationMessage
            }
        }
    }
    
    var usernameStatusIndicator: some View {
        Group {
            if isCheckingUsername {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(AppColors.accent)
            } else if let available = usernameAvailable {
                Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(available ? .green : .red)
                    .scaleEffect(available ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: available)
            }
        }
    }
    
    var usernameValidationMessage: some View {
        HStack(spacing: 8) {
            let trimmedUsername = editedUsername.trimmingCharacters(in: .whitespaces)
            
            if !isValidUsername(trimmedUsername) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                
                Text("Username must be 3-20 characters with letters, numbers, or underscores only")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            } else if let available = usernameAvailable, !isCheckingUsername {
                if !available {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    
                    Text("This username is already taken")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                } else if trimmedUsername.lowercased() != originalUsername.lowercased() {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    
                    Text("Username is available")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.3), value: usernameAvailable)
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
    
    func modernTextField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        icon: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Field Label
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primary)
            }
            
            // Text Field
            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .disableAutocorrection(keyboardType == .emailAddress)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.background)
                        .stroke(AppColors.secondary.opacity(0.3), lineWidth: 1.5)
                        .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 2)
                )
        }
    }
    
    func modernReadOnlyField(title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Field Label
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.secondary)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.secondary)
            }
            
            // Text Display
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.card.opacity(0.5))
                        .stroke(AppColors.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    func setupInitialValues() {
        print("[EditProfileView] setupInitialValues called")
        if let user = viewModel.user {
            print("[EditProfileView] Setting up initial values:")
            print("  - Full Name: '\(user.fullName)'")
            print("  - Username: '\(user.username ?? "nil")'")
            print("  - Email: '\(user.email)'")
            
            editedFullName = user.fullName
            // Make sure the username field is populated with current username
            let currentUsername = user.username ?? ""
            editedUsername = currentUsername
            originalUsername = currentUsername
            
            print("[EditProfileView] Values set:")
            print("  - editedFullName: '\(editedFullName)'")
            print("  - editedUsername: '\(editedUsername)'")
            print("  - originalUsername: '\(originalUsername)'")
        } else {
            print("[EditProfileView] No user found in viewModel")
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
                }
            }
        }
    }
    
    func handleUsernameChange(_ newValue: String) {
        // Cancel previous check
        usernameCheckTask?.cancel()
        
        // Reset state
        usernameAvailable = nil
        
        // Only check if username is valid and different from original
        let trimmedUsername = newValue.trimmingCharacters(in: .whitespaces).lowercased()
        if isValidUsername(trimmedUsername) && trimmedUsername != originalUsername.lowercased() {
            usernameCheckTask = Task {
                await checkUsernameAvailability(trimmedUsername)
            }
        }
    }
    
    var usernameFieldBorderColor: Color {
        if editedUsername.isEmpty {
            return AppColors.secondary.opacity(0.3)
        }
        
        let trimmedUsername = editedUsername.trimmingCharacters(in: .whitespaces)
        if !isValidUsername(trimmedUsername) {
            return .red.opacity(0.8)
        }
        
        if let available = usernameAvailable, !isCheckingUsername {
            return available ? .green.opacity(0.8) : .red.opacity(0.8)
        }
        
        return AppColors.accent.opacity(0.6)
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
    
    func isValidUsername(_ username: String) -> Bool {
        guard !username.isEmpty else { return true }
        
        return username.count >= 3 && 
               username.count <= 20 &&
               username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
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
        
        // Upload image if selected
        if let image = viewModel.selectedImage {
            viewModel.uploadProfileImage(image)
        }
        
        // Save user changes and wait for completion
        if hasChanges {
            await withCheckedContinuation { continuation in
                viewModel.saveUser(updatedUser) { error in
                    if let error = error {
                        print("[EditProfileView] Save error: \(error.localizedDescription)")
                    } else {
                        print("[EditProfileView] Save completed successfully")
                    }
                    continuation.resume()
                }
            }
        }
        
        // Close with animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
    
    var profileImageView: some View {
        Group {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(AppColors.card)
            } else if let downloadedImage = viewModel.downloadedProfileImage {
                Image(uiImage: downloadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(AppColors.card)
            } else if let urlString = viewModel.user?.profileImageUrl, 
                      !urlString.isEmpty, 
                      let url = URL(string: urlString) {
                // Profile image için URL'e timestamp ekleyerek fresh data al
                let freshUrl = URL(string: "\(urlString)?t=\(Date().timeIntervalSince1970)")
                
                KFImage(freshUrl)
                    .configureForProfileImage(size: CGSize(width: 200, height: 200))
                    .placeholder {
                        ZStack {
                            AppColors.card
                            
                            VStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                                    .scaleEffect(0.8)
                                
                                Text("Loading...")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AppColors.secondary)
                            }
                        }
                    }
                    .onProgress { receivedSize, totalSize in
                        let progress = Double(receivedSize) / Double(totalSize)
                        print("[EditProfileView] Image loading progress: \(Int(progress * 100))%")
                    }
                    .onSuccess { result in
                        print("[EditProfileView] Image loaded successfully")
                    }
                    .onFailure { error in
                        print("[EditProfileView] Image loading failed: \(error.localizedDescription)")
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(AppColors.card)
            } else {
                ZStack {
                    AppColors.card
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(AppColors.secondary.opacity(0.6))
                }
            }
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
            print("[EditProfileViewWrapper] onAppear - fetching user data")
            viewModel.fetchCurrentUser()
        }
    }
} 
