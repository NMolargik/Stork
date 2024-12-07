import Foundation

public enum DeliveryError: Error, LocalizedError {
    case notFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case firebaseError(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Delivery Not Found: \(message)"
        case .creationFailed(let message):
            return "Delivery Creation Failed: \(message)"
        case .updateFailed(let message):
            return "Delivery Update Failed: \(message)"
        case .deletionFailed(let message):
            return "Delivery Deletion Failed: \(message)"
        case .firebaseError(let message):
            return "Firebase Error: \(message)"
        case .unknown(let message):
            return "Unknown Delivery Error: \(message)"
        }
    }
}
