import SwiftUI
import Kingfisher

struct SentRecipeCard: View {
    let recipe: SentSharedRecipe
    let sender: User?      // Gönderen (her zaman sen)
    let receiver: User?    // Alıcı (tarifi gönderdiğin kişi)
    let recipeDetail: Recipe?
    var onTap: () -> Void  // Yeni eklenen onTap parametresi

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Gönderen profil fotoğrafı (her zaman en solda)
            if let sender = sender {
                if let urlString = sender.profileImageUrl, !urlString.isEmpty {
                    KFImage(URL(string: urlString))
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 96, height: 96)))
                        .placeholder {
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(AppColors.accent)
                                )
                                .frame(width: 48, height: 48)
                        }
                        .fade(duration: 0.3)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                } else {
                    Circle().fill(AppColors.primary.opacity(0.2))
                        .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                        .frame(width: 48, height: 48)
                        .shadow(color: AppColors.primary.opacity(0.12), radius: 4, y: 1)
                }
            } else {
                Circle().fill(AppColors.primary.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay(ProgressView())
            }
            
            // Baloncuk
            ZStack(alignment: .bottomTrailing) {
                BubbleWithTail()
                    .fill(AppColors.card)
                    .shadow(color: AppColors.shadow, radius: 4, y: 1)
                
                // Baloncuk içeriği
                HStack(alignment: .center, spacing: 16) {
                    // En solda: Yemek resmi
                    if let imageUrl = recipeDetail?.image, !imageUrl.isEmpty {
                        KFImage(URL(string: imageUrl))
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 96, height: 96)))
                            .placeholder {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppColors.card.opacity(0.8))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(AppColors.accent)
                                    )
                                    .frame(width: 48, height: 48)
                            }
                            .fade(duration: 0.3)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.leading, 8)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .padding(.leading, 8)
                    }
                    // Ortada: Yemek adı
                    Text(recipeDetail?.name ?? "Loading...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 8)
                    // En sağda: Alıcı avatarı + isim + badge
                    if let receiver = receiver {
                        VStack(spacing: 4) {
                            if let url = receiver.profileImageUrl, !url.isEmpty {
                                KFImage(URL(string: url))
                                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 56, height: 56)))
                                    .placeholder {
                                        Circle()
                                            .fill(AppColors.primary.opacity(0.1))
                                            .overlay(
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                                    .tint(AppColors.accent)
                                            )
                                            .frame(width: 28, height: 28)
                                    }
                                    .fade(duration: 0.3)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 28, height: 28)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                    .overlay(Text(receiver.fullName.prefix(1)).font(.caption).foregroundColor(AppColors.primary))
                            }
                            Text(receiver.fullName)
                                .font(.caption)
                                .foregroundColor(AppColors.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
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
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(height: 90, alignment: .center)
                
                // Emoji overlay
                if let reaction = recipe.reaction {
                    emojiOverlay(for: reactionTypeToString(reaction), offsetX: 18, offsetY: 18)
                }
            }
            .frame(height: 90)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .padding(.trailing, 24)
        .onTapGesture(perform: onTap)  // onTap gesture'ını ekliyoruz
    }
    
    // MARK: - Helper Methods
    private func reactionTypeToString(_ reaction: ReactionType?) -> String? {
        return reaction?.rawValue
    }
    
    func emojiText(for reaction: String) -> String {
        switch reaction {
        case "like": return "👍"
        case "neutral": return "😐"
        case "dislike": return "👎"
        default: return ""
        }
    }

    @ViewBuilder
    private func emojiOverlay(for reaction: String?, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        if let reaction = reaction {
            Text(emojiText(for: reaction))
                .font(.system(size: 20))
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 4, y: 1)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: offsetX, y: offsetY)
                .zIndex(2)
        }
    }
} 