import Foundation

enum MusterError: Error, LocalizedError {
    case notFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Muster Not Found: \(message)"
        case .creationFailed(let message):
            return "Muster Creation Failed: \(message)"
        case .updateFailed(let message):
            return "Muster Update Failed: \(message)"
        case .deletionFailed(let message):
            return "Muster Deletion Failed: \(message)"
        case .unknown(let message):
            return "Unknown Muster Error: \(message)"
        }
    }
}
