//
//  MusterRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the interface for remote data source interactions related to musters.
public protocol MusterRemoteDataSourceInterface {
    /// Creates a new muster record and returns the newly created `Muster`.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Returns: The newly created `Muster`.
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation fails.
    ///   - `MusterError.firebaseError`: If the Firestore operation fails.
    func createMuster(muster: Muster) async throws -> Muster

    /// Updates an existing muster record and returns the updated `Muster`.
    ///
    /// - Parameter muster: The `Muster` object containing the updated data.
    /// - Returns: The updated `Muster`.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - `MusterError.firebaseError`: If the Firestore operation fails.
    func updateMuster(muster: Muster) async throws -> Muster
    
    /// Retrieves a single muster by its unique ID.
    ///
    /// - Parameter id: The unique ID of the muster to fetch.
    /// - Returns: A `Muster` object representing the muster with the specified ID.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster cannot be found.
    ///   - `MusterError.firebaseError`: If the Firestore operation fails.
    func getMuster(byId id: String) async throws -> Muster

    /// Lists musters based on optional filters.
    ///
    /// - Parameters:
    ///   - profileIds: An optional filter for profile IDs associated with the muster. If `nil`, this filter is ignored.
    ///   - primaryHospitalId: An optional filter for the primary hospital ID associated with the muster. If `nil`, this filter is ignored.
    ///   - administratorProfileIds: An optional filter for administrator profile IDs. If `nil`, this filter is ignored.
    ///   - name: An optional filter for the muster name. If `nil`, this filter is ignored.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws: `MusterError` if the operation fails or no musters are found.
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
    /// - Throws: `MusterError` if sending fails or the Firestore operation fails.
    func sendMusterInvite(invite: MusterInvite, userId: String) async throws
    
    /// Collects all muster invitations for a user.
    ///
    /// - Parameter userId: The user ID associated with potential muster invites.
    /// - Returns: An array of `MusterInvite` objects for the specified user.
    /// - Throws: `MusterError` if the operation fails or the Firestore operation fails.
    func collectUserMusterInvites(userId: String) async throws -> [MusterInvite]
    
    /// Collects all muster invitations for a specific muster.
    ///
    /// - Parameter musterId: The muster ID associated with potential invites.
    /// - Returns: An array of `MusterInvite` objects for the specified muster.
    /// - Throws: `MusterError` if the operation fails or the Firestore operation fails.
    func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite]
    
    /// Cancels a previously sent muster invitation.
    ///
    /// - Parameter invitationId: The ID from the invitation to cancel.
    /// - Throws: `MusterError` if cancellation fails or the Firestore operation fails.
    func cancelMusterInvite(invitationId: String) async throws
    
    /// Deletes all muster invitations associated with a given muster.
    ///
    /// - Parameter musterId: The ID of the muster whose invitations should be deleted.
    /// - Throws: `MusterError` if deletion fails or the Firestore operation fails.
    func deleteMusterInvites(musterId: String) async throws
    
    /// Deletes an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.deletionFailed`: If the deletion operation fails.
    ///   - `MusterError.firebaseError`: If the Firestore operation fails.
    func deleteMuster(muster: Muster) async throws
}
