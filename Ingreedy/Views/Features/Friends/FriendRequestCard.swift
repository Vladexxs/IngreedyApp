import SwiftUI
import Kingfisher

enum FriendRequestAction {
    case accept
    case reject
}

struct FriendRequestCard: View {
    let request: FriendRequest
    let onAction: (FriendRequestAction) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            Group {
                if let imageURL = request.fromUserProfileImageUrl, 
                   let url = URL(string: imageURL) {
                    KFImage(url)
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 100, height: 100)))
                        .cacheMemoryOnly() // Profile resimleri için memory-only cache
                        .forceRefresh() // Fresh data
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppColors.accent.opacity(0.3), lineWidth: 1))
                } else {
                    // Display initials if no profile image
                    Circle()
                        .fill(AppColors.accent.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(getInitials(from: request.fromUserName))
                                .font(.headline.bold())
                                .foregroundColor(AppColors.accent)
                        )
                }
            }
            
            // Request Info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.fromUserName)
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
                
                Text("@\(request.fromUserUsername)")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondary)
                
                Text(timeAgoString(from: request.timestamp))
                    .font(.caption)
                    .foregroundColor(AppColors.secondary.opacity(0.7))
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 8) {
                Button(action: { onAction(.accept) }) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .clipShape(Circle())
                }
                
                Button(action: { onAction(.reject) }) {
                    Image(systemName: "person.badge.minus.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColors.card)
        .cornerRadius(16)
        .shadow(color: AppColors.shadow.opacity(0.1), radius: 4, y: 2)
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

#Preview {
    FriendRequestCard(
        request: FriendRequest(
            id: "1",
            fromUserId: "user1",
            toUserId: "user2",
            fromUserName: "John Doe",
            fromUserUsername: "johndoe",
            toUserName: "Jane Smith",
            toUserUsername: "janesmith",
            fromUserProfileImageUrl: nil,
            toUserProfileImageUrl: nil,
            status: .pending,
            timestamp: Date()
        )
    ) { action in
        // Handle action
    }
    .padding()
} 