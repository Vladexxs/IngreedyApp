import SwiftUI
import Kingfisher

struct ReceivedRecipeCard: View {
    let recipe: ReceivedSharedRecipe
    let user: User?
    let recipeDetail: Recipe?
    var reaction: String?
    var onTap: () -> Void
    var onLongPress: () -> Void
    var showEmojiMenu: Bool
    var onEmojiSelect: (String) -> Void
    var hideEmojiOverlay: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Spacer(minLength: 0)
            ZStack(alignment: .bottomLeading) {
                BubbleWithTailRight()
                    .fill(AppColors.card)
                    .shadow(color: AppColors.shadow, radius: 4, y: 1)
                HStack(alignment: .center, spacing: 16) {
                    // En solda: Sadece isim ve altında 'Gönderildi' badge'i
                    if let user = user {
                        VStack(spacing: 2) {
                            Text(user.fullName)
                                .font(.caption)
                                .foregroundColor(AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text("by")
                                .font(.caption2)
                                .foregroundColor(AppColors.primary)
                            Text("Sent")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.accent)
                                .cornerRadius(10)
                        }
                        .frame(minWidth: 60, alignment: .center)
                    }
                    // Ortada: Yemek adı
                    Text(recipeDetail?.name ?? "Loading...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    // En sağda: Yemek resmi
                    if let imageUrl = recipeDetail?.image, !imageUrl.isEmpty {
                        KFImage(URL(string: imageUrl))
                .configureForRecipeImage()
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.trailing, 8)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(height: 90, alignment: .center)
                // Emoji overlay sol alt köşe
                if let reaction = reaction, !hideEmojiOverlay {
                    emojiOverlay(for: reaction, offsetX: -18, offsetY: 18)
                }
            }
            .frame(height: 90)
            // Profil fotoğrafı en sağda (balonun dışında)
            if let user = user {
                if let urlString = user.profileImageUrl, !urlString.isEmpty {
                    KFImage(URL(string: urlString))
                        .configureForProfileImage()
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                } else {
                    Circle().fill(AppColors.primary.opacity(0.2))
                        .overlay(Text(user.fullName.prefix(1)).font(.caption).foregroundColor(AppColors.primary))
                        .frame(width: 48, height: 48)
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                }
            } else {
                Circle().fill(AppColors.primary.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay(ProgressView())
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .padding(.leading, 24)
        .onTapGesture(perform: onTap)
        .onLongPressGesture(perform: onLongPress)
    }

    @ViewBuilder
    private func emojiOverlay(for reaction: String, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        Text(emojiText(for: reaction))
            .font(.system(size: 20))
            .padding(6)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.15), radius: 4, y: 1)
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            .offset(x: offsetX, y: offsetY) // Offset'i dışarıdan al
            .zIndex(2)
    }
    
    private func emojiText(for reaction: String) -> String {
        switch reaction {
        case "like": return "👍"
        case "neutral": return "😐"
        case "dislike": return "👎"
        default: return ""
        }
    }
} 