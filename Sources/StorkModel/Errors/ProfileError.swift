import Foundation

public enum ProfileError: Error, LocalizedError {
    case notFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case authenticationFailed(String)
    case passwordResetFailed(String)
    case fetchFailed(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Profile Not Found: \(message)"
        case .creationFailed(let message):
            return "Profile Creation Failed: \(message)"
        case .updateFailed(let message):
            return "Profile Update Failed: \(message)"
        case .deletionFailed(let message):
            return "Profile Deletion Failed: \(message)"
        case .authenticationFailed(let message):
            return "Authentication Failed: \(message)"
        case .passwordResetFailed(let message):
            return "Password Reset Failed: \(message)"
        case .fetchFailed(let message):
            return "Profile fetch failed: \(message)"
        case .unknown(let message):
            return "Unknown Error: \(message)"
        }
    }
}
