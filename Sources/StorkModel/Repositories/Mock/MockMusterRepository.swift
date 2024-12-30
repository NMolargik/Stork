//
//  MockMusterRepository.swift
//
//
//  Created by Nick Molargik on 11/20/24.
//

import Foundation

/// A mock implementation of the `MusterRepositoryInterface` protocol for testing purposes.
public class MockMusterRepository: MusterRepositoryInterface {
    // MARK: - Properties

    /// A list of mock Musters used for in-memory storage.
    private var musters: [Muster] = []
    
    /// A list of mock invitations used for in-memory storage.
    private var invites: [MusterInvite] = []

    // MARK: - Initializer

    /// Initializes the mock repository with optional sample data.
    ///
    /// - Parameters:
    ///   - musters: An array of `Muster` objects to initialize the repository with. Defaults to an empty array.
    ///   - invites: An array of `MusterInvite` objects to initialize the repository with. Defaults to an empty array.
    public init(musters: [Muster] = [], invites: [MusterInvite] = []) {
        self.musters = musters
        
        // For demonstration, add a couple sample invites
        self.invites.append(
            MusterInvite(
                id: UUID().description,
                recipientId: "",
                recipientName: "Nick",
                senderName: "Jessica",
                musterName: "Admin Muster",
                musterId: ""
            )
        )
        
        self.invites.append(
            MusterInvite(
                id: UUID().description,
                recipientId: "",
                recipientName: "Nick",
                senderName: "Jeanne",
                musterName: "Parkview Muster",
                musterId: ""
            )
        )
    }

    // MARK: - Create

    /// Creates a new muster record and returns the newly created `Muster`.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Returns: The newly created `Muster`.
    /// - Throws: `MusterError.creationFailed` if a muster with the same ID already exists.
    public func createMuster(muster: Muster) async throws -> Muster {
        if musters.contains(where: { $0.id == muster.id }) {
            throw MusterError.creationFailed("Muster with ID \(muster.id) already exists.")
        }
        musters.append(muster)
        return muster
    }

    // MARK: - Update

    /// Updates an existing muster record and returns the updated `Muster`.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Returns: The updated `Muster`.
    /// - Throws: `MusterError.notFound` if the muster does not exist.
    public func updateMuster(muster: Muster) async throws -> Muster {
        guard let index = musters.firstIndex(where: { $0.id == muster.id }) else {
            throw MusterError.notFound("Muster with ID \(muster.id) not found.")
        }
        musters[index] = muster
        return muster
    }

    // MARK: - Read

    /// Fetches a single muster by its unique ID.
    ///
    /// - Parameter id: The unique ID of the muster.
    /// - Returns: A `Muster` object matching the ID.
    /// - Throws: `MusterError.notFound` if no muster with the specified ID exists.
    public func getMuster(byId id: String) async throws -> Muster {
        guard let muster = musters.first(where: { $0.id == id }) else {
            throw MusterError.notFound("Muster with ID \(id) not found.")
        }
        return muster
    }

    /// Lists musters based on optional filters.
    ///
    /// - Parameters:
    ///   - profileIds: An optional filter for profile IDs associated with the muster.
    ///   - primaryHospitalId: An optional filter for the muster’s primary hospital ID.
    ///   - administratorProfileIds: An optional filter for administrator profile IDs.
    ///   - name: An optional filter for the muster name (case-insensitive substring).
    /// - Returns: An array of `Muster` objects matching the specified filters.
    public func listMusters(
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil
    ) async throws -> [Muster] {
        musters.filter { muster in
            let nameFilter = name?.lowercased()
            
            let profileMatch = profileIds == nil
                || profileIds!.allSatisfy { muster.profileIds.contains($0) }
            
            // Fix the logic for primaryHospitalId to compare with muster’s property
            let hospitalMatch = primaryHospitalId == nil
                || muster.primaryHospitalId == primaryHospitalId
            
            let adminMatch = administratorProfileIds == nil
                || administratorProfileIds!.allSatisfy { muster.administratorProfileIds.contains($0) }
            
            let nameMatch = nameFilter == nil
                || muster.name.lowercased().contains(nameFilter!)
            
            return profileMatch && hospitalMatch && adminMatch && nameMatch
        }
    }

    // MARK: - Invitation Methods

    /// Sends a profile an invite to join a muster.
    ///
    /// - Parameter invite: The `MusterInvite` object defining the invitation.
    /// - Parameter userId: The ID of the user that is being invited.
    /// - Throws: `MusterError.invitationFailed` if an invite with the same ID already exists.
    public func sendMusterInvite(invite: MusterInvite, userId: String) async throws {
        // Ensure no duplicate invite with the same ID
        if invites.contains(where: { $0.id == invite.id }) {
            throw MusterError.invitationFailed("An invite with ID \(invite.id) already exists.")
        }
        invites.append(invite)
    }

    /// Collects all muster invitations for a user.
    ///
    /// - Parameter userId: The user ID associated with potential muster invites.
    /// - Returns: An array of `MusterInvite` objects for the specified user.
    public func collectUserMusterInvites(userId: String) async throws -> [MusterInvite] {
        invites.filter { $0.recipientId == userId }
    }

    /// Collects all muster invitations for a specific muster.
    ///
    /// - Parameter musterId: The muster ID associated with the invitations.
    /// - Returns: An array of `MusterInvite` objects for the specified muster.
    public func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite] {
        invites.filter { $0.musterId == musterId }
    }

    /// Cancels a sent muster invitation.
    ///
    /// - Parameter invitationId: The ID of the invitation to cancel.
    /// - Throws: `MusterError.failedToCancelInvite` if the invitation is not found.
    public func cancelMusterInvite(invitationId: String) async throws {
        guard let index = invites.firstIndex(where: { $0.id == invitationId }) else {
            throw MusterError.failedToCancelInvite("Invite with ID \(invitationId) not found.")
        }
        invites.remove(at: index)
    }

    /// Deletes all muster invitations associated with a given muster.
    ///
    /// - Parameter musterId: The muster ID whose invitations should be deleted.
    public func deleteMusterInvites(musterId: String) async throws {
        invites.removeAll(where: { $0.musterId == musterId })
    }

    /// Deletes an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws: `MusterError.deletionFailed` if the muster is not found.
    public func deleteMuster(muster: Muster) async throws {
        guard let index = musters.firstIndex(where: { $0.id == muster.id }) else {
            throw MusterError.deletionFailed("Failed to delete muster with ID \(muster.id).")
        }
        musters.remove(at: index)
    }
}
