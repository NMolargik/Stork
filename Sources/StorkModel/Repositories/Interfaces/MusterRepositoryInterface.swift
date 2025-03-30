//
//  MusterRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation

/// A protocol defining the repository interface for managing Muster entities.
///
/// This protocol serves as an abstraction layer between the domain layer and
/// the data layer, allowing the application to interact with Muster-related
/// data sources in a consistent manner.
public protocol MusterRepositoryInterface {
    
    /// Creates a new Muster record and returns the newly created `Muster`.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Returns: The newly created `Muster` with any server-updated fields (e.g., auto-generated ID).
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation fails.
    ///   - `MusterError`: For other failures during the creation (e.g., Firestore or parsing).
    func createMuster(muster: Muster) async throws -> Muster
    
    /// Updates an existing Muster record and returns the updated `Muster`.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Returns: The updated `Muster`. If your backend applies additional updates (e.g. timestamps),
    ///   this should contain those changes.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - `MusterError`: For other failures during the update (e.g., Firestore or parsing).
    func updateMuster(muster: Muster) async throws -> Muster
    
    /// Retrieves a single Muster by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the Muster to fetch.
    /// - Returns: A `Muster` object representing the fetched Muster.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster cannot be found.
    ///   - `MusterError`: If another error occurs during the fetch operation.
    func getMuster(byId id: String) async throws -> Muster
    
    /// Lists Musters based on optional filtering criteria.
    ///
    /// - Parameters:
    ///   - profileIds: An optional filter for profile IDs associated with the muster.
    ///   - primaryHospitalId: An optional filter for the primary hospital ID associated with the muster.
    ///   - administratorProfileIds: An optional filter for the administrators' profile IDs.
    ///   - name: An optional filter for the muster name.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError`: If the operation fails or if no matching Musters are found (depending on your error-handling).
    func listMusters(
        profileIds: [String]?,
        primaryHospitalId: String?,
        administratorProfileIds: [String]?,
        name: String?
    ) async throws -> [Muster]
    
    /// Sends a profile an invite to join a muster.
    ///
    /// - Parameters:
    ///   - invite: The `MusterInvite` object defining the invitation.
    ///   - userId: The ID of the user being invited.
    /// - Throws:
    ///   - `MusterError.invitationFailed`: If sending the invite fails (if you track such specific errors).
    ///   - `MusterError`: For other general failures.
    func sendMusterInvite(invite: MusterInvite, userId: String) async throws
    
    /// Collects all muster invitations for a user.
    ///
    /// - Parameter userId: The user ID associated with potential muster invites.
    /// - Returns: An array of `MusterInvite` objects for the specified user.
    /// - Throws:
    ///   - `MusterError.failedToCollectInvitations`: If fetching fails, or other domain errors.
    ///   - `MusterError`: For other general failures.
    func collectUserMusterInvites(userId: String) async throws -> [MusterInvite]
    
    /// Collects all muster invitations for a specific muster.
    ///
    /// - Parameter musterId: The muster ID associated with potential invites.
    /// - Returns: An array of `MusterInvite` objects for the specified muster.
    /// - Throws:
    ///   - `MusterError.failedToCollectInvitations`: If fetching fails.
    ///   - `MusterError`: For other general failures.
    func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite]
    
    /// Cancels a sent muster invitation by deleting it.
    ///
    /// - Parameter invitationId: The ID of the invitation to cancel.
    /// - Throws:
    ///   - `MusterError.failedToCancelInvite`: If deletion fails.
    ///   - `MusterError`: For other general failures.
    func cancelMusterInvite(invitationId: String) async throws
    
    /// Deletes all muster invitations associated with a given muster.
    ///
    /// - Parameter musterId: The ID of the muster whose invitations should be deleted.
    /// - Throws:
    ///   - `MusterError.deletionFailed`: If the operation fails to delete invites.
    ///   - `MusterError`: For other failures.
    func deleteMusterInvites(musterId: String) async throws
    
    /// Deletes an existing Muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.deletionFailed`: If the deletion operation fails.
    ///   - `MusterError`: For other failures during the deletion.
    func deleteMuster(muster: Muster) async throws
}
