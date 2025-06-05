import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Shared Recipe Service Implementation
final class SharedRecipeService: FirebaseService, SharedRecipeServiceProtocol {
    
    // MARK: - Constants
    private enum Collections {
        static let users = "users"
        static let sharedRecipes = "sharedRecipes"
        static let received = "received"
        static let sent = "sent"
    }
    
    private enum Fields {
        static let fromUserId = "fromUserId"
        static let toUserId = "toUserId"
        static let recipeId = "recipeId"
        static let reaction = "reaction"
        static let timestamp = "timestamp"
        static let sentRecipeId = "sentRecipeId"
        static let receivedRecipeId = "receivedRecipeId"
    }
    
    // MARK: - Send Recipe
    func sendRecipe(toUserId: String, recipeId: Int) async throws {
        let currentUserId = try ensureAuthenticated()
        log("Sending recipe \(recipeId) to user: \(toUserId)")
        
        let timestamp = Date()
        
        // Create received document first and get its ID
        let receivedRef = createReceivedRecipeReference(userId: toUserId)
        let receivedDocRef = receivedRef.document()
        let receivedDocId = receivedDocRef.documentID
        
        let receivedData = createReceivedRecipeData(
            fromUserId: currentUserId,
            recipeId: recipeId,
            timestamp: timestamp
        )
        
        try await receivedDocRef.setData(receivedData)
        
        // Create sent document
        let sentRef = createSentRecipeReference(userId: currentUserId)
        let sentDocRef = sentRef.document()
        let sentDocId = sentDocRef.documentID
        
        let sentData = createSentRecipeData(
            toUserId: toUserId,
            recipeId: recipeId,
            timestamp: timestamp,
            receivedRecipeId: receivedDocId
        )
        
        try await sentDocRef.setData(sentData)
        
        // Update received document with sent recipe ID
        try await receivedDocRef.updateData([Fields.sentRecipeId: sentDocId])
        
        log("Recipe \(recipeId) sent successfully to user: \(toUserId)")
    }
    
    // MARK: - Fetch Received Recipes
    func fetchReceivedRecipes() async throws -> [ReceivedSharedRecipe] {
        let currentUserId = try ensureAuthenticated()
        log("Fetching received recipes")
        
        let ref = createReceivedRecipeReference(userId: currentUserId)
        let snapshot = try await ref.order(by: Fields.timestamp, descending: true).getDocuments()
        
        let recipes = snapshot.documents.compactMap { document in
            createReceivedSharedRecipe(from: document)
        }
        
        log("Found \(recipes.count) received recipes")
        return recipes
    }
    
    // MARK: - Fetch Sent Recipes
    func fetchSentRecipes() async throws -> [SentSharedRecipe] {
        let currentUserId = try ensureAuthenticated()
        log("Fetching sent recipes")
        
        let ref = createSentRecipeReference(userId: currentUserId)
        let snapshot = try await ref.order(by: Fields.timestamp, descending: true).getDocuments()
        
        var sentRecipes: [SentSharedRecipe] = []
        
        for document in snapshot.documents {
            if let recipe = await createSentSharedRecipe(from: document) {
                sentRecipes.append(recipe)
            }
        }
        
        log("Found \(sentRecipes.count) sent recipes")
        return sentRecipes
    }
    
    // MARK: - React to Recipe
    func reactToRecipe(receivedRecipeId: String, reaction: ReactionType) async throws {
        let currentUserId = try ensureAuthenticated()
        log("Reacting to recipe: \(receivedRecipeId) with reaction: \(reaction.rawValue)")
        
        let reactionString = reaction.rawValue
        
        // Update received document
        let receivedRef = createReceivedRecipeReference(userId: currentUserId)
            .document(receivedRecipeId)
        
        try await receivedRef.updateData([Fields.reaction: reactionString])
        
        // Get sent recipe ID and update sender's document
        let receivedDoc = try await receivedRef.getDocument()
        
        if let sentRecipeId = receivedDoc.data()?[Fields.sentRecipeId] as? String,
           let fromUserId = receivedDoc.data()?[Fields.fromUserId] as? String {
            
            let sentRef = createSentRecipeReference(userId: fromUserId)
                .document(sentRecipeId)
            
            try await sentRef.updateData([Fields.reaction: reactionString])
            log("Reaction updated successfully for both documents")
        } else {
            log("Could not find sent recipe reference", level: .warning)
        }
    }
    
    // MARK: - React to Recipe (String-based)
    func reactToRecipe(receivedRecipeId: String, reaction: String) async throws {
        guard let reactionType = ReactionType(rawValue: reaction) else {
            throw ServiceError.invalidData
        }
        try await reactToRecipe(receivedRecipeId: receivedRecipeId, reaction: reactionType)
    }
}

// MARK: - Private Helper Methods
private extension SharedRecipeService {
    
    func createReceivedRecipeReference(userId: String) -> CollectionReference {
        return userDocument(userId)
            .collection(Collections.sharedRecipes)
            .document(Collections.received)
            .collection(Collections.received)
    }
    
    func createSentRecipeReference(userId: String) -> CollectionReference {
        return userDocument(userId)
            .collection(Collections.sharedRecipes)
            .document(Collections.sent)
            .collection(Collections.sent)
    }
    
    func createReceivedRecipeData(fromUserId: String, recipeId: Int, timestamp: Date) -> [String: Any] {
        return [
            Fields.fromUserId: fromUserId,
            Fields.recipeId: recipeId,
            Fields.reaction: NSNull(),
            Fields.timestamp: Timestamp(date: timestamp),
            Fields.sentRecipeId: NSNull()
        ]
    }
    
    func createSentRecipeData(toUserId: String, recipeId: Int, timestamp: Date, receivedRecipeId: String) -> [String: Any] {
        return [
            Fields.toUserId: toUserId,
            Fields.recipeId: recipeId,
            Fields.timestamp: Timestamp(date: timestamp),
            Fields.receivedRecipeId: receivedRecipeId
        ]
    }
    
    func createReceivedSharedRecipe(from document: QueryDocumentSnapshot) -> ReceivedSharedRecipe? {
        let data = document.data()
        
        guard let fromUserId = data[Fields.fromUserId] as? String,
              let recipeId = data[Fields.recipeId] as? Int,
              let timestamp = (data[Fields.timestamp] as? Timestamp)?.dateValue() else {
            log("Failed to parse received recipe from document: \(document.documentID)", level: .warning)
            return nil
        }
        
        let reactionString = data[Fields.reaction] as? String
        let reaction = stringToReactionType(reactionString)
        
        return ReceivedSharedRecipe(
            id: document.documentID,
            fromUserId: fromUserId,
            fromUserName: nil,
            recipeId: recipeId,
            reaction: reaction,
            timestamp: timestamp
        )
    }
    
    func createSentSharedRecipe(from document: QueryDocumentSnapshot) async -> SentSharedRecipe? {
        let data = document.data()
        
        guard let toUserId = data[Fields.toUserId] as? String,
              let recipeId = data[Fields.recipeId] as? Int,
              let timestamp = (data[Fields.timestamp] as? Timestamp)?.dateValue() else {
            log("Failed to parse sent recipe from document: \(document.documentID)", level: .warning)
            return nil
        }
        
        let receivedRecipeId = data[Fields.receivedRecipeId] as? String
        var reaction: ReactionType? = nil
        
        // Fetch reaction from receiver's document if available
        if let receivedId = receivedRecipeId {
            reaction = await fetchReactionFromReceiver(toUserId: toUserId, receivedRecipeId: receivedId)
        }
        
        return SentSharedRecipe(
            id: document.documentID,
            toUserId: toUserId,
            toUserName: nil,
            recipeId: recipeId,
            reaction: reaction,
            timestamp: timestamp
        )
    }
    
    func fetchReactionFromReceiver(toUserId: String, receivedRecipeId: String) async -> ReactionType? {
        do {
            let receivedDocRef = createReceivedRecipeReference(userId: toUserId)
                .document(receivedRecipeId)
            
            let receivedDoc = try await receivedDocRef.getDocument()
            
            if let receivedData = receivedDoc.data(),
               let reactionString = receivedData[Fields.reaction] as? String {
                return stringToReactionType(reactionString)
            }
        } catch {
            log("Error fetching reaction from receiver: \(error.localizedDescription)", level: .warning)
        }
        
        return nil
    }
    
    func stringToReactionType(_ reactionString: String?) -> ReactionType? {
        guard let reactionString = reactionString else { return nil }
        return ReactionType(rawValue: reactionString)
    }
} 