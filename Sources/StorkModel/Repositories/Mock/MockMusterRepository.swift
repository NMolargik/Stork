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
    /// - Parameter musters: An array of `Muster` objects to initialize the repository with.
    ///   Defaults to an empty array.
    /// - Parameter invites: An array of `MusterInvite` objects to initialize the repository with.
    ///   Defaults to an empty array.
    public init(musters: [Muster] = [], invites: [MusterInvite] = []) {
        self.musters = musters
        
        self.invites.append(
            MusterInvite(id: UUID().description, recipientId: "", recipientName: "Nick", senderName: "Jessica", musterName: "Admin Muster", musterId: "", primaryHospitalName: "Parkview Regional Medical Center", message: "Hey this is the message", primaryColor: "red")
    
        )
        
        self.invites.append(
            MusterInvite(id: UUID().description, recipientId: "", recipientName: "Nick", senderName: "Jeanne", musterName: "Parkview Muster", musterId: "", primaryHospitalName: "Parkview Regional Medical Center", message: "Hey this is another message", primaryColor: "purple")
        )
    }

    // MARK: - Methods
    
    /// Creates a new muster record.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Throws: `MusterError.creationFailed` if a muster with the same ID already exists.
    public func createMuster(muster: Muster) async throws {
        if musters.contains(where: { $0.id == muster.id }) {
            throw MusterError.creationFailed("Muster with ID \(muster.id) already exists.")
        }
        musters.append(muster)
    }

    /// Updates an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Throws: `MusterError.notFound` if the muster does not exist.
    public func updateMuster(muster: Muster) async throws {
        guard let index = musters.firstIndex(where: { $0.id == muster.id }) else {
            throw MusterError.notFound("Muster with ID \(muster.id) not found.")
        }
        musters[index] = muster
    }

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
    ///   - primaryHospitalId: An optional filter for hospital ID associated with the muster
    ///   - administratorProfileIds: An optional filter for the administrators' profile IDs.
    ///   - name: An optional filter for the muster name.
    ///   - primaryColor: An optional filter for the muster’s primary color.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    public func listMusters(
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil,
        primaryColor: String? = nil
    ) async throws -> [Muster] {
        return musters.filter { muster in
            let nameFilter = name?.lowercased()
            return
                (profileIds == nil || profileIds!.allSatisfy { muster.profileIds.contains($0) }) &&
                (primaryHospitalId == nil || primaryHospitalId == primaryHospitalId) &&
                (administratorProfileIds == nil || administratorProfileIds!.allSatisfy { muster.administratorProfileIds.contains($0) }) &&
                (nameFilter == nil || muster.name.lowercased().contains(nameFilter!)) &&
                (primaryColor == nil || muster.primaryColor == primaryColor)
        }
    }
    
    // MARK: - Invitation Methods
    
    /// Sends a profile an invite to join a muster.
    ///
    /// - Parameter invite: The `MusterInvite` object defining the invitation.
    /// - Parameter userId: The id of the user that is being invited.
    /// - Throws:
    public func sendMusterInvite(invite: MusterInvite, userId: String) async throws {
        // Ensure no duplicate invite with the same ID
        if invites.contains(where: { $0.id == invite.id }) {
            throw MusterError.invitationFailed("An invite with ID \(invite.id) already exists.")
        }
        invites.append(invite)
    }
    
    /// Collects all muster invitations for a user.
    ///
    /// - Parameter userId: The userId associated with potential muster invites.
    /// - Throws:
    public func collectUserMusterInvites(userId: String) async throws -> [MusterInvite] {
        return self.invites.filter { $0.recipientId == userId }
    }
    
    /// Collects all muster invitations for a specific muster.
    ///
    /// - Parameter musterId: The musterId associated with potential muster invites.
    /// - Throws:
    public func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite] {
        return invites.filter { $0.musterId == musterId }
    }
    
    /// Cancels a sent muster invitation.
    ///
    /// - Parameter invitationId: The id of the invitation.
    /// - Throws:
    public func cancelMusterInvite(invitationId: String) async throws {
        guard let index = invites.firstIndex(where: { $0.id == invitationId }) else {
            throw MusterError.failedToCancelInvite("Invite with ID \(invitationId) not found.")
        }
        invites.remove(at: index)
    }
    
    /// Deletes an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws: `MusterError.deletionFailed` if the muster does not exist.
    public func deleteMuster(muster: Muster) async throws {
        guard let index = musters.firstIndex(where: { $0.id == muster.id }) else {
            throw MusterError.deletionFailed("Failed to delete muster with ID \(muster.id).")
        }
        musters.remove(at: index)
    }
}
