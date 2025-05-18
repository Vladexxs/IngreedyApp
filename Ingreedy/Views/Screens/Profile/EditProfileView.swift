import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?
    
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
            VStack(spacing: 24) {
                // Üstte yer alan iptal butonu
                HStack {
                    Button("İptal") { 
                        isPresented = false 
                    }
                    .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Profil Fotoğrafı
                ZStack {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 100, height: 100)
                    } else if let urlString = viewModel.user?.profileImageUrl, let cleanUrl = cleanURL(from: urlString) {
                        AsyncImage(url: cleanUrl) { phase in
                            if let image = phase.image {
                                image.resizable()
                            } else if let error = phase.error {
                                Circle()
                                    .fill(Color.gray)
                                    .onAppear {
                                        print("Profil fotoğrafı yüklenemedi: \(error.localizedDescription)")
                                    }
                            } else {
                                ProgressView()
                            }
                        }
                        .id(cleanUrl.absoluteString)
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                        .onAppear {
                            print("Edit profile clean URL: \(cleanUrl.absoluteString)")
                        }
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