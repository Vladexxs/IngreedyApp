import Foundation

enum AppError: LocalizedError {
    case networkError(String)
    case decodingError(String)
    case validationError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return message
        case .decodingError(let message):
            return message
        case .validationError(let message):
            return message
        case .unknown:
            return "An unknown error occurred."
        }
    }
} 