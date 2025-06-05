import Foundation
import Combine

// MARK: - Notification Service Protocol
protocol NotificationServiceProtocol: ObservableObject {
    var hasNewSharedRecipe: Bool { get set }
    
    func startListening()
    func stopListening()
    func clearNotification()
    func setRouter(_ router: Router)
} 