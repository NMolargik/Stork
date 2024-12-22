//
//  MusterRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the repository interface for managing Muster entities.
///
/// This protocol serves as an abstraction layer between the domain layer and
/// the data layer, allowing the application to interact with Muster-related
/// data sources in a consistent manner.
public protocol MusterRepositoryInterface {
    /// Creates a new Muster record.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation fails.
    ///   - `MusterError`: For other failures during the creation.
    func createMuster(muster: Muster) async throws
    
    /// Updates an existing Muster record.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - `MusterError`: For other failures during the update.
    func updateMuster(muster: Muster) async throws
    
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
    ///   - primaryHospitalId: An optional filter for hospital Id associated with the muster.
    ///   - administratorProfileIds: An optional filter for the administrators' profile IDs.
    ///   - name: An optional filter for the muster name.
    ///   - primaryColor: An optional filter for the muster’s primary color.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError`: If the operation fails or no matching Musters are found.
    func listMusters(
        profileIds: [String]?,
        primaryHospitalId: String?,
        administratorProfileIds: [String]?,
        name: String?,
        primaryColor: String?
    ) async throws -> [Muster]
    
    /// Sends a profile an invite to join a muster
    ///
    /// - Parameter invite: The `MusterInvite` object defining the invitaiton
    /// - Parameter userId: The id of the user that is being invited
    /// - Throws:
    func sendMusterInvite(invite: MusterInvite, userId: String) async throws
    
    /// Collects all muster invitations for a user
    ///
    /// - Parameter userId: The userId associated with potential muster invites
    /// - Throws:
    func collectUserMusterInvites(userId: String) async throws -> [MusterInvite]
    
    /// Collects all muster invitations for a muster
    ///
    /// - Parameter musterId: The musterId associated with potential muster invites
    /// - Throws:
    func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite]
    
    /// Cancels a sent muster invitation
    ///
    /// - Parameter invitationId: The id from the invitation
    /// - Throws:
    func cancelMusterInvite(invitationId: String) async throws
    
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
