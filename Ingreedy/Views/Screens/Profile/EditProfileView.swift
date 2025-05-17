import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profil Fotoğrafı
                ZStack {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 100, height: 100)
                    } else if let urlString = viewModel.user?.profileImageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Circle().fill(Color.gray)
                        }
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 100, height: 100)
                    }
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Circle()
                            .strokeBorder(Color.accentColor, lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.accentColor)
                            )
                    }
                    .opacity(0.7)
                }

                Spacer()

                Button("Kaydet") {
                    if let image = viewModel.selectedImage {
                        viewModel.uploadProfileImage(image)
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Profili Düzenle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { isPresented = false }
                }
            }
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