import Foundation
import FirebaseFirestore
import FirebaseAuth

class SharedRecipeService: SharedRecipeServiceProtocol {
    private let db = Firestore.firestore()
    
    // MARK: - Helper Methods
    private func stringToReactionType(_ reactionString: String?) -> ReactionType? {
        guard let reactionString = reactionString else { return nil }
        return ReactionType(rawValue: reactionString)
    }
    
    // MARK: - Public Methods
    // Tarif gönderme
    func sendRecipe(toUserId: String, recipeId: Int) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let timestamp = Date()
        
        // Received (alıcıda received koleksiyonu) dökümanını önce oluştur, ID'sini al
        let receivedRef = db.collection("users").document(toUserId)
            .collection("sharedRecipes").document("received")
            .collection("received")
        let receivedDocRef = receivedRef.document() // Yeni döküman referansı oluştur
        let receivedDocId = receivedDocRef.documentID
        
        let receivedData: [String: Any] = [
            "fromUserId": currentUserId,
            "recipeId": recipeId,
            "reaction": NSNull(), // Başlangıçta tepki yok
            "timestamp": Timestamp(date: timestamp),
            "sentRecipeId": NSNull() // Başlangıçta boş - gönderen tarafın ID'si daha sonra eklenecek
        ]
        try await receivedDocRef.setData(receivedData)
        
        // Sent (gönderenin sent koleksiyonu)
        let sentRef = db.collection("users").document(currentUserId)
            .collection("sharedRecipes").document("sent")
            .collection("sent")
        let sentDocRef = sentRef.document() // Yeni döküman referansı oluştur
        let sentDocId = sentDocRef.documentID
        
        let sentData: [String: Any] = [
            "toUserId": toUserId,
            "recipeId": recipeId,
            "timestamp": Timestamp(date: timestamp),
            "receivedRecipeId": receivedDocId // Alıcıdaki dökümanın ID'si
        ]
        try await sentDocRef.setData(sentData)
        
        // Alıcıdaki received dökümanına gönderen tarafın ID'sini ekle
        try await receivedDocRef.updateData(["sentRecipeId": sentDocId])
    }
    
    // Bana gönderilen tarifleri çekme
    func fetchReceivedRecipes() async throws -> [ReceivedSharedRecipe] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        let ref = db.collection("users").document(currentUserId)
            .collection("sharedRecipes").document("received")
            .collection("received")
        let snapshot = try await ref.order(by: "timestamp", descending: true).getDocuments()
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            let id = doc.documentID
            let fromUserId = data["fromUserId"] as? String ?? ""
            let recipeId = data["recipeId"] as? Int ?? 0
            let reactionString = data["reaction"] as? String
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            
            return ReceivedSharedRecipe(
                id: id,
                fromUserId: fromUserId,
                fromUserName: nil, // Bu bilgi veritabanında saklanmıyor, gerekirse sonra eklenebilir
                recipeId: recipeId,
                reaction: stringToReactionType(reactionString),
                timestamp: timestamp
            )
        }
    }
    
    // Benim gönderdiğim tarifleri çekme
    func fetchSentRecipes() async throws -> [SentSharedRecipe] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        let ref = db.collection("users").document(currentUserId)
            .collection("sharedRecipes").document("sent")
            .collection("sent")
        let snapshot = try await ref.order(by: "timestamp", descending: true).getDocuments()
        
        var sentRecipes: [SentSharedRecipe] = []
        for doc in snapshot.documents {
            let data = doc.data()
            let id = doc.documentID
            let toUserId = data["toUserId"] as? String ?? ""
            let recipeId = data["recipeId"] as? Int ?? 0
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            let receivedRecipeId = data["receivedRecipeId"] as? String // Alıcıdaki dökümanın ID'si
            
            var reactionString: String? = nil
            // Eğer receivedRecipeId varsa, alıcının received koleksiyonundaki
            // ilgili dökümanı (receivedRecipeId ile belirtilen) çekip tepkiyi al.
            if let receivedId = receivedRecipeId {
                print("[DEBUG] fetchSentRecipes - Sent dökümanından çekilen receivedRecipeId: \(receivedId)")
                print("[DEBUG] fetchSentRecipes - Şu anki currentUserId: \(currentUserId)")
                print("[DEBUG] fetchSentRecipes - Alıcı ID (toUserId): \(toUserId)") // <-- Alıcı ID'sini de logla
                
                let receivedDocRef = db.collection("users").document(toUserId) // <-- Alıcı ID'sini (toUserId) kullan
                    .collection("sharedRecipes").document("received")
                    .collection("received").document(receivedId)
                    
                print("[DEBUG] fetchSentRecipes - Alıcının received koleksiyonundan döküman aranıyor: \(receivedDocRef.path)")
                    
                let receivedDoc = try? await receivedDocRef.getDocument()
                
                if let receivedDoc = receivedDoc, receivedDoc.exists {
                    if let receivedData = receivedDoc.data() {
                        reactionString = receivedData["reaction"] as? String
                        print("[DEBUG] fetchSentRecipes - Alıcının received dökümanından tepki çekildi: \(reactionString ?? "Yok")")
                    } else {
                         print("[DEBUG] fetchSentRecipes - Alıcının received dökümanında veri yok: \(receivedId)")
                    }
                } else {
                     print("[DEBUG] fetchSentRecipes - Alıcının received dökümanı bulunamadı: \(receivedId)")
                }
            } else {
                 print("[DEBUG] fetchSentRecipes - Sent dökümanında receivedRecipeId yok.")
            }
            
            sentRecipes.append(SentSharedRecipe(
                id: id,
                toUserId: toUserId,
                toUserName: nil, // Bu bilgi veritabanında saklanmıyor, gerekirse sonra eklenebilir
                recipeId: recipeId,
                reaction: stringToReactionType(reactionString),
                timestamp: timestamp
            ))
        }
        return sentRecipes
    }
    
    // Gelen tarife tepki verme
    func reactToRecipe(receivedRecipeId: String, reaction: ReactionType) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let reactionString = reaction.rawValue
        
        // Alıcıdaki dökümanı güncelle
        let receivedRef = db.collection("users").document(currentUserId)
            .collection("sharedRecipes").document("received")
            .collection("received").document(receivedRecipeId)
        try await receivedRef.updateData(["reaction": reactionString])
        
        // Gönderendeki dökümanı bul ve güncelle
        // Alıcıdaki dökümandan sentRecipeId'yi al
        let receivedDoc = try await receivedRef.getDocument()
        if let sentRecipeId = receivedDoc.data()?["sentRecipeId"] as? String,
           let fromUserId = receivedDoc.data()?["fromUserId"] as? String {
            
            let sentRef = db.collection("users").document(fromUserId)
                .collection("sharedRecipes").document("sent")
                .collection("sent").document(sentRecipeId)
            
            try await sentRef.updateData(["reaction": reactionString])
        }
    }
    
    // Convenience method for string-based reaction (backward compatibility)
    func reactToRecipe(receivedRecipeId: String, reaction: String) async throws {
        guard let reactionType = ReactionType(rawValue: reaction) else {
            throw NSError(domain: "SharedRecipeService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid reaction type: \(reaction)"])
        }
        try await reactToRecipe(receivedRecipeId: receivedRecipeId, reaction: reactionType)
    }
} 