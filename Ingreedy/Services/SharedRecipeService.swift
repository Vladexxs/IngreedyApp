import Foundation
import FirebaseFirestore
import FirebaseAuth

class SharedRecipeService {
    private let db = Firestore.firestore()
    
    // Tarif gönderme
    func sendRecipe(toUserId: String, recipeId: Int) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let timestamp = Date()
        
        // Sent (gönderenin sent koleksiyonu)
        let sentRef = db.collection("users").document(currentUserId)
            .collection("sharedRecipes").document("sent")
            .collection("sent")
        let sentData: [String: Any] = [
            "toUserId": toUserId,
            "recipeId": recipeId,
            "timestamp": Timestamp(date: timestamp)
        ]
        _ = try await sentRef.addDocument(data: sentData)
        
        // Received (alıcıda received koleksiyonu)
        let receivedRef = db.collection("users").document(toUserId)
            .collection("sharedRecipes").document("received")
            .collection("received")
        let receivedData: [String: Any] = [
            "fromUserId": currentUserId,
            "recipeId": recipeId,
            "reaction": NSNull(),
            "timestamp": Timestamp(date: timestamp)
        ]
        _ = try await receivedRef.addDocument(data: receivedData)
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
            let reaction = data["reaction"] as? String
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            return ReceivedSharedRecipe(
                id: id,
                fromUserId: fromUserId,
                recipeId: recipeId,
                reaction: reaction,
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
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            let id = doc.documentID
            let toUserId = data["toUserId"] as? String ?? ""
            let recipeId = data["recipeId"] as? Int ?? 0
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            return SentSharedRecipe(
                id: id,
                toUserId: toUserId,
                recipeId: recipeId,
                timestamp: timestamp
            )
        }
    }
    
    // Gelen tarife tepki verme
    func reactToRecipe(receivedRecipeId: String, reaction: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let ref = db.collection("users").document(currentUserId)
            .collection("sharedRecipes").document("received")
            .collection("received").document(receivedRecipeId)
        try await ref.updateData(["reaction": reaction])
    }
} 