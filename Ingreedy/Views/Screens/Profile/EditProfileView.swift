import SwiftUI
import PhotosUI
import Kingfisher

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?
    @State private var editedFullName: String = ""
    
    private func cleanURL(from urlString: String) -> URL? {
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let originalUrl = URL(string: encoded) else {
            return nil
        }
        
        var components = URLComponents(url: originalUrl, resolvingAgainstBaseURL: false)
        components?.port = nil
        let cleanUrl = components?.url ?? originalUrl
        return cleanUrl
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Top bar with Cancel
                HStack {
                    Button("Cancel") { 
                        isPresented = false 
                    }
                    .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Profile Photo
                VStack(spacing: 12) {
                    ZStack {
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: 120, height: 120)
                                .shadow(radius: 8)
                        } else if let urlString = viewModel.user?.profileImageUrl, let cleanUrl = cleanURL(from: urlString) {
                            KFImage(cleanUrl)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: 120, height: 120)
                                .shadow(radius: 8)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                        }
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Circle()
                                .strokeBorder(Color.accentColor, lineWidth: 2)
                                .frame(width: 120, height: 120)
                                .background(Color.clear)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.accentColor)
                                        .background(Circle().fill(Color.white.opacity(0.8)).frame(width: 48, height: 48))
                                        .offset(y: 40)
                                )
                        }
                        .opacity(0.7)
                    }
                    Button("Change Photo") {
                        // PhotosPicker zaten yukarıda
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .disabled(true)
                }
                
                // User Info
                VStack(spacing: 8) {
                    if let user = viewModel.user {
                        TextField("Full Name", text: $editedFullName)
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
                .onAppear {
                    if let user = viewModel.user {
                        editedFullName = user.fullName
                    }
                }
                
                Spacer()
                
                // Save Button
                Button("Save") {
                    if let image = viewModel.selectedImage {
                        viewModel.uploadProfileImage(image)
                    }
                    if var user = viewModel.user, !editedFullName.trimmingCharacters(in: .whitespaces).isEmpty, user.fullName != editedFullName {
                        user.fullName = editedFullName
                        viewModel.saveUser(user)
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .padding(.bottom, 24)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { newItem in
                if let newItem {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            viewModel.selectedImage = uiImage
                        }
                    }
                }
            }
        }
    }
} 
