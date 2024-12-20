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

    // MARK: - Methods
    
    /// Creates a new muster record.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation operation fails.
    ///   - `MusterError`: For other failures during the creation operation.
    public func createMuster(muster: Muster) async throws {
        do {
            try await remoteDataSource.createMuster(muster: muster)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.creationFailed("Failed to create muster: \(error.localizedDescription)")
        }
    }

    /// Updates an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - `MusterError`: For other failures during the update operation.
    public func updateMuster(muster: Muster) async throws {
        do {
            try await remoteDataSource.updateMuster(muster: muster)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.updateFailed("Failed to update muster: \(error.localizedDescription)")
        }
    }
    
    /// Fetches a single muster by its unique ID.
    ///
    /// - Parameter id: The unique ID of the muster to fetch.
    /// - Returns: A `Muster` object representing the fetched muster.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster with the specified ID does not exist.
    ///   - `MusterError`: For other failures during the fetch operation.
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
    ///   - primaryHospitalId: An optional filter for the hospital id associated with the muster
    ///   - name: An optional filter for the muster name.
    ///   - administratorProfileId: An optional filter for the administrator's profile ID.
    ///   - primaryColor: An optional filter for the muster’s primary color.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError`: For failures during the fetch operation.
    public func listMusters(
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil,
        primaryColor: String? = nil
    ) async throws -> [Muster] {
        do {
            return try await remoteDataSource.listMusters(
                profileIds: profileIds,
                primaryHospitalId: primaryHospitalId,
                administratorProfileIds: administratorProfileIds,
                name: name,
                primaryColor: primaryColor
            )
        }
        catch let error as MusterError {
           throw error
       } catch {
           throw MusterError.unknown("Failed to list musters: \(error.localizedDescription)")
       }
    }
    
    /// Sends a profile an invite to join a muster
    ///
    /// - Parameter invite: The `MusterInvite` object defining the invitaiton
    /// - Parameter userId: The id of the user that is being invited
    /// - Throws:
    public func sendMusterInvite(invite: MusterInvite, userId: String) async throws {
        do {
            try await remoteDataSource.sendMusterInvite(invite: invite, userId: userId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.invitationFailed("Failed to create muster invitation: \(error.localizedDescription)")
        }
    }

    
    /// Collects all muster invitations for a user
    ///
    /// - Parameter userId: The userId associated with potential muster invites
    /// - Throws:
    public func collectUserMusterInvites(userId: String) async throws -> [MusterInvite] {
        do {
            return try await remoteDataSource.collectUserMusterInvites(userId: userId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.failedToCollectInvitations("Failed to collect your invites: \(error.localizedDescription)")
        }
    }
    
    /// Collects all muster invitations for a muster
    ///
    /// - Parameter musterId: The musterId associated with potential muster invites
    /// - Throws:
    public func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite] {
        do {
            return try await remoteDataSource.collectInvitesForMuster(musterId: musterId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.failedToCollectInvitations("Failed to collect muster's invites: \(error.localizedDescription)")
        }
    }
    
    /// Cancels a sent muster invitation
    ///
    /// - Parameter invitationId: The id from the invitation
    /// - Throws:
    public func cancelMusterInvite(invitationId: String) async throws {
        do {
            try await remoteDataSource.cancelMusterInvite(invitationId: invitationId)
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.failedToCancelInvite("Failed to cancel invite: \(error.localizedDescription)")
        }
    }
    
    /// Deletes an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.deletionFailed`: If the deletion operation fails.
    ///   - `MusterError`: For other failures during the deletion operation.
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
