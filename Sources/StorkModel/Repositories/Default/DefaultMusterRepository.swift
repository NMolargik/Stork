//
//  DefaultMusterRepository.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A repository implementation for managing muster-related operations.
/// Handles interactions with the remote data source for musters.
public class DefaultMusterRepository: MusterRepositoryInterface {
    // MARK: - Properties

    /// The remote data source for muster operations.
    private let remoteDataSource: MusterRemoteDataSourceInterface

    // MARK: - Initializer

    /// Initializes the repository with a remote data source.
    ///
    /// - Parameter remoteDataSource: An instance of `MusterRemoteDataSourceInterface`.
    public init(remoteDataSource: MusterRemoteDataSourceInterface) {
        self.remoteDataSource = remoteDataSource
    }

    // MARK: - Create
    
    /// Creates a new muster record and returns the newly created `Muster`.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Returns: The newly created `Muster`, including any auto-generated fields (e.g., ID).
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation operation fails.
    ///   - Other `MusterError` variants for different failure scenarios.
    public func createMuster(muster: Muster) async throws -> Muster {
        do {
            // The data source now returns a `Muster` instead of `Void`.
            let createdMuster = try await remoteDataSource.createMuster(muster: muster)
            return createdMuster
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.creationFailed("Failed to create muster: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    /// Updates an existing muster record and returns the updated `Muster`.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Returns: The updated `Muster`, reflecting any changes from the server.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - Other `MusterError` variants for additional failure scenarios.
    public func updateMuster(muster: Muster) async throws -> Muster {
        do {
            let updatedMuster = try await remoteDataSource.updateMuster(muster: muster)
            return updatedMuster
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.updateFailed("Failed to update muster: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Read

    /// Fetches a single muster by its unique ID.
    ///
    /// - Parameter id: The unique ID of the muster to fetch.
    /// - Returns: A `Muster` object representing the fetched muster.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster with the specified ID does not exist.
    ///   - Other `MusterError` variants for failures during the fetch operation.
    public func getMuster(byId id: String) async throws -> Muster {
        do {
            return try await remoteDataSource.getMuster(byId: id)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.unknown("Failed to fetch muster with ID \(id): \(error.localizedDescription)")
        }
    }
    
    /// Lists musters based on optional filter criteria.
    ///
    /// - Parameters:
    ///   - profileIds: An optional filter for profile IDs associated with the muster.
    ///   - primaryHospitalId: An optional filter for the hospital ID associated with the muster.
    ///   - administratorProfileIds: An optional filter for the administrators' profile IDs.
    ///   - name: An optional filter for the muster name.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError` variants if the operation fails.
    public func listMusters(
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil
    ) async throws -> [Muster] {
        do {
            return try await remoteDataSource.listMusters(
                profileIds: profileIds,
                primaryHospitalId: primaryHospitalId,
                administratorProfileIds: administratorProfileIds,
                name: name
            )
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.unknown("Failed to list musters: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Invites

    /// Sends a profile an invite to join a muster.
    ///
    /// - Parameters:
    ///   - invite: The `MusterInvite` object defining the invitation.
    ///   - userId: The ID of the user that is being invited.
    /// - Throws:
    ///   - `MusterError.invitationFailed`: If the invitation fails.
    ///   - Other `MusterError` variants for different failure scenarios.
    public func sendMusterInvite(invite: MusterInvite, userId: String) async throws {
        do {
            try await remoteDataSource.sendMusterInvite(invite: invite, userId: userId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.invitationFailed("Failed to create muster invitation: \(error.localizedDescription)")
        }
    }

    /// Collects all muster invitations for a user.
    ///
    /// - Parameter userId: The user ID associated with potential muster invites.
    /// - Returns: An array of `MusterInvite` objects.
    /// - Throws:
    ///   - `MusterError.failedToCollectInvitations`: If collection fails.
    ///   - Other `MusterError` variants for different failure scenarios.
    public func collectUserMusterInvites(userId: String) async throws -> [MusterInvite] {
        do {
            return try await remoteDataSource.collectUserMusterInvites(userId: userId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.failedToCollectInvitations("Failed to collect your invites: \(error.localizedDescription)")
        }
    }
    
    /// Collects all muster invitations for a specific muster.
    ///
    /// - Parameter musterId: The muster ID associated with the invitations.
    /// - Returns: An array of `MusterInvite` objects.
    /// - Throws:
    ///   - `MusterError.failedToCollectInvitations`: If the collection fails.
    ///   - Other `MusterError` variants for additional failure modes.
    public func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite] {
        do {
            return try await remoteDataSource.collectInvitesForMuster(musterId: musterId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.failedToCollectInvitations("Failed to collect muster invites: \(error.localizedDescription)")
        }
    }
    
    /// Cancels a previously sent muster invitation.
    ///
    /// - Parameter invitationId: The ID of the invitation to cancel.
    /// - Throws:
    ///   - `MusterError.failedToCancelInvite`: If the cancellation fails.
    ///   - Other `MusterError` variants for different failure scenarios.
    public func cancelMusterInvite(invitationId: String) async throws {
        do {
            try await remoteDataSource.cancelMusterInvite(invitationId: invitationId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.failedToCancelInvite("Failed to cancel invite: \(error.localizedDescription)")
        }
    }
    
    /// Deletes all muster invitations associated with a given muster.
    ///
    /// - Parameter musterId: The ID of the muster whose invitations should be deleted.
    /// - Throws:
    ///   - `MusterError.failedToCollectInvitations`, `MusterError.deletionFailed`, or other relevant errors.
    public func deleteMusterInvites(musterId: String) async throws {
        do {
            try await remoteDataSource.deleteMusterInvites(musterId: musterId)
        } catch {
            // Re-throwing the original error might be simpler if your domain logic doesn't require further wrapping
            throw error
        }
    }
    
    // MARK: - Delete

    /// Deletes an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.deletionFailed`: If the deletion operation fails.
    ///   - Other `MusterError` variants for additional failure scenarios.
    public func deleteMuster(muster: Muster) async throws {
        do {
            try await remoteDataSource.deleteMuster(muster: muster)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.deletionFailed("Failed to close your muster: \(error.localizedDescription)")
        }
    }
}
