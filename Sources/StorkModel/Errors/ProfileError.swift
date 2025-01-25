import Foundation

public enum ProfileError: Error, LocalizedError {
    case notFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case authenticationFailed(String)
    case passwordResetFailed(String)
    case fetchFailed(String)
    case signOutFailed(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Profile not found"
        case .creationFailed(let message):
            return "Profile creation failed. Please try again!"
        case .updateFailed(let message):
            return "Profile update failed. Please try again!"
        case .deletionFailed(let message):
            return "Profile deletion failed. Please try again!"
        case .authenticationFailed(let message):
            return "Authentication failed. Please try again!"
        case .passwordResetFailed(let message):
            return "Password Reset failed. Please try again!"
        case .fetchFailed(let message):
            return "Failed to get profile."
        case .signOutFailed(let message):
            return "Sign out failed. Please try again!"
        case .unknown(let message):
            return "Unknown profile error."
        }
    }
}
