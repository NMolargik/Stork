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
            print("Delivery Error: \(message)")
            return "Delivery not found. \(message)"
        case .limitReached(let message):
            print("Delivery Error: \(message)")
            return "You have already reached your delivery limit for today! \(message)"
        case .creationFailed(let message):
            print("Delivery Error: \(message)")
            return "Delivery creation failed. \(message)"
        case .updateFailed(let message):
            print("Delivery Error: \(message)")
            return "Delivery update failed. Please try again! \(message)"
        case .deletionFailed(let message):
            print("Delivery Error: \(message)")
            return "Delivery deletion failed. Please try again! \(message)"
        case .firebaseError(let message):
            print("Delivery Error: \(message)")
            return "Network error. Please try again! \(message)"
        case .unknown(let message):
            print("Delivery Error: \(message)")
            return "Unknown delivery error. \(message)"
        }
    }
}
