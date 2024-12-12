import Foundation

public enum MusterError: Error, LocalizedError {
    case notFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case invitationFailed(String)
    case invitationResponseFailed(String)
    case failedToCollectInvitations(String)
    case failedToCancelInvite(String)
    case unknown(String)

    public var errorDescription: String? {
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
        case .invitationFailed(let message):
            return "Invitation Failed To Send: \(message)"
        case .invitationResponseFailed(let message):
            return "Failed to respond to invitation: \(message)"
        case .failedToCollectInvitations(let message):
            return "Failed to collect invitations: \(message)"
        case .failedToCancelInvite(let message):
            return "Failed to cancel invitation: \(message)"
        }
    }
}
