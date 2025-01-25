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
            return "Muster Nnt found."
        case .creationFailed(let message):
            return "Muster creation failed. Please try again!"
        case .updateFailed(let message):
            return "Muster update failed. Please try again!"
        case .deletionFailed(let message):
            return "Muster deletion failed. Please try again!"
        case .unknown(let message):
            return "Unknown muster error."
        case .invitationFailed(let message):
            return "Invitation failed to send. Please try again!"
        case .invitationResponseFailed(let message):
            return "Invitation response failed. Please try again!"
        case .failedToCollectInvitations(let message):
            return "Failed to collect invitations. Please try again!"
        case .failedToCancelInvite(let message):
            return "Failed to cancel invitation. Please try again!"
        }
    }
}
