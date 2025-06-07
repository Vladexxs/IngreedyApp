import SwiftUI

struct AddFriendSheet: View {
    @EnvironmentObject var friendViewModel: FriendViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accent)
                    
                    Text("Add Friend")
                        .font(.title.bold())
                        .foregroundColor(AppColors.primary)
                    
                    Text("Enter the username to send a friend request")
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Input Section
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "at")
                            .foregroundColor(AppColors.accent)
                            .frame(width: 20)
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(AppColors.text)
                            .tint(AppColors.accent)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(AppColors.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text("Example: @johnsmith")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary.opacity(0.7))
                }
                
                // Action Button
                Button(action: {
                    friendViewModel.friendUsername = username
                    friendViewModel.sendFriendRequest()
                }) {
                    HStack {
                        if friendViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.headline)
                        }
                        
                        Text(friendViewModel.isLoading ? "Sending..." : "Send Request")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [AppColors.accent, AppColors.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: AppColors.accent.opacity(0.4), radius: 8, y: 4)
                }
                .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || friendViewModel.isLoading)
                .opacity(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                
                // Error/Success Messages
                if let errorMessage = friendViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if let successMessage = friendViewModel.successMessage {
                    Text(successMessage)
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(AppColors.background)
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .onChange(of: friendViewModel.successMessage) { _ in
                if friendViewModel.successMessage != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                        friendViewModel.clearMessages()
                    }
                }
            }
        }
    }
}

#Preview {
    AddFriendSheet()
        .environmentObject(FriendViewModel())
} 