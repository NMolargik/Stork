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
            print("Profile Error: \(message)")
            return "Profile not found. \(message)"
        case .creationFailed(let message):
            print("Profile Error: \(message)")
            return "Profile creation failed. Please try again! \(message)"
        case .updateFailed(let message):
            print("Profile Error: \(message)")
            return "Profile update failed. Please try again! \(message)"
        case .deletionFailed(let message):
            print("Profile Error: \(message)")
            return "Profile deletion failed. Please try again! \(message)"
        case .authenticationFailed(let message):
            print("Profile Error: \(message)")
            return "Authentication failed. Please try again! \(message)"
        case .passwordResetFailed(let message):
            print("Profile Error: \(message)")
            return "Password reset failed. Please try again! \(message)"
        case .fetchFailed(let message):
            print("Profile Error: \(message)")
            return "Failed to get profile. \(message)"
        case .signOutFailed(let message):
            print("Profile Error: \(message)")
            return "Sign out failed. Please try again! \(message)"
        case .unknown(let message):
            print("Profile Error: \(message)")
            return "Unknown profile error. \(message)"
        }
    }
}
