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
            print("Muster Error: \(message)")
            return "Muster not found. \(message)"
        case .creationFailed(let message):
            print("Muster Error: \(message)")
            return "Muster creation failed. Please try again! \(message)"
        case .updateFailed(let message):
            print("Muster Error: \(message)")
            return "Muster update failed. Please try again! \(message)"
        case .deletionFailed(let message):
            print("Muster Error: \(message)")
            return "Muster deletion failed. Please try again! \(message)"
        case .invitationFailed(let message):
            print("Muster Error: \(message)")
            return "Invitation failed to send. Please try again! \(message)"
        case .invitationResponseFailed(let message):
            print("Muster Error: \(message)")
            return "Invitation response failed. Please try again! \(message)"
        case .failedToCollectInvitations(let message):
            print("Muster Error: \(message)")
            return "Failed to collect invitations. Please try again! \(message)"
        case .failedToCancelInvite(let message):
            print("Muster Error: \(message)")
            return "Failed to cancel invitation. Please try again! \(message)"
        case .unknown(let message):
            print("Muster Error: \(message)")
            return "Unknown muster error. \(message)"
        }
    }
}
