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
            print("Hospital Error: \(message)")
            return "Hospital not found. Adjust your search! \(message)"
        case .creationFailed(let message):
            print("Hospital Error: \(message)")
            return "Hospital creation failed. Please try again! \(message)"
        case .updateFailed(let message):
            print("Hospital Error: \(message)")
            return "Hospital update failed. Please try again! \(message)"
        case .deletionFailed(let message):
            print("Hospital Error: \(message)")
            return "Hospital deletion failed. Please try again! \(message)"
        case .unknown(let message):
            print("Hospital Error: \(message)")
            return "Unknown hospital error. \(message)"
        }
    }
}
