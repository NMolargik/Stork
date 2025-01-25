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
            return "Hospital not found. Adjust your search!"
        case .creationFailed(let message):
            return "Hospital creation failed. Please try again!"
        case .updateFailed(let message):
            return "Hospital update failed. Please try again!"
        case .deletionFailed(let message):
            return "Hospital deletion failed. Please try again!"
        case .unknown(let message):
            return "Unknown hospital error."
        }
    }
}
