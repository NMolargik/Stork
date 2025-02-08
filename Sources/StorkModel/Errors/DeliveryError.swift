import Foundation

public enum DeliveryError: Error, LocalizedError {
    case notFound(String)
    case limitReached(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case firebaseError(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Delivery not found"
        case .limitReached(let message):
            return "You have already reached your delivery limit for today!"
        case .creationFailed(let message):
            return "Delivery creation failed. \(message)"
        case .updateFailed(let message):
            return "Delivery update failed. Please try again!"
        case .deletionFailed(let message):
            return "Delivery deletion failed. Please try again!"
        case .firebaseError(let message):
            return "Network error. Please try again!"
        case .unknown(let message):
            return "Unknown delivery error"
        }
    }
}
