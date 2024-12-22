import Foundation

public enum HospitalError: Error, LocalizedError {
    case notFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Hospital Not Found: \(message)"
        case .creationFailed(let message):
            return "Hospital Creation Failed: \(message)"
        case .updateFailed(let message):
            return "Hospital Update Failed: \(message)"
        case .deletionFailed(let message):
            return "Hospital Deletion Failed: \(message)"
        case .unknown(let message):
            return "Unknown Hospital Error: \(message)"
        }
    }
}
