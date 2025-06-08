import SwiftUI
import PhotosUI
import Kingfisher

struct EditProfilePhotoSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var isAnimating: Bool
    
    var body: some View {
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
    
    private var profileImageContainer: some View {
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
            
            // Upload progress overlay
            if viewModel.isUploading {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 135, height: 135)
                    .overlay(
                        AnimatedProgressRing(
                            progress: viewModel.uploadProgress,
                            lineWidth: 4,
                            size: 90
                        )
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isUploading)
    }
    
    private var photoPickerButton: some View {
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
    
    private var profileImageView: some View {
        ZStack {
            // Background: Always show URL image if available
            if let urlString = viewModel.user?.profileImageUrl, 
               !urlString.isEmpty, 
               let url = URL(string: urlString) {
                
                KFImage(url)
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
                    .onSuccess { _ in }
                    .onFailure { _ in }
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
            
            // Overlay: Show selected image when available, fade out when upload complete
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .background(AppColors.card)
                    .opacity(viewModel.isUploading && viewModel.uploadProgress >= 1.0 ? 0 : 1)
                    .animation(.easeOut(duration: 0.8), value: viewModel.uploadProgress >= 1.0)
            }
        }
    }
} 