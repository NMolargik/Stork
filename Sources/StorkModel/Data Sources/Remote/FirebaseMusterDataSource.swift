//
//  FirebaseMusterDataSource.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation

#if !SKIP
import FirebaseCore
import FirebaseFirestore
#else
import SkipFirebaseCore
import SkipFirebaseFirestore
#endif

/// A data source responsible for interacting with the Firebase Firestore database to manage muster records.
public actor FirebaseMusterDataSource: MusterRemoteDataSourceInterface {
    /// The Firestore database instance.
    private let firestore: Firestore
    
    public static var shared = FirebaseMusterDataSource()

    /// Initializes the FirebaseMusterDataSource with a Firestore instance.
    public init() {
        self.firestore = Firestore.firestore()
    }

    // MARK: - Create a New Muster Record

    /// Creates a new muster record in Firestore and returns the newly created `Muster`.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Returns: The newly created `Muster` (optionally re-fetched if you need server-updated fields).
    /// - Throws:
    ///   - `MusterError.creationFailed`: If an error occurs while creating the muster.
    @MainActor
    public func createMuster(muster: Muster) async throws -> Muster {
        do {
            // Convert muster to dictionary and write to Firestore
            let data = muster.dictionary
            try await firestore.collection("Muster").document(muster.id).setData(data)
            
            return muster
        } catch {
            throw MusterError.creationFailed("Failed to create muster: \(error.localizedDescription)")
        }
    }

    // MARK: - Update an Existing Muster Record

    /// Updates an existing muster record in Firestore and returns the updated `Muster`.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Returns: The updated `Muster` (optionally re-fetched if you need server-updated fields).
    /// - Throws:
    ///   - `MusterError.updateFailed`: If an error occurs while updating the muster.
    @MainActor
    public func updateMuster(muster: Muster) async throws -> Muster {
        do {
            let data = muster.dictionary
            try await firestore.collection("Muster").document(muster.id).updateData(data)

            return muster
        } catch {
            throw MusterError.updateFailed("Failed to update muster: \(error.localizedDescription)")
        }
    }

    /// Fetches a single muster by its unique ID.
    ///
    /// - Parameter id: The unique ID of the muster to fetch.
    /// - Returns: A `Muster` object representing the muster with the specified ID.
    /// - Throws:
    ///   - `MusterError.notFound`: If no muster with the specified ID is found.
    ///   - `MusterError.firebaseError`: If an error occurs while fetching the muster.
    @MainActor
    public func getMuster(byId id: String) async throws -> Muster {
        do {
            let document = try await firestore.collection("Muster").document(id).getDocument()

            // Safely unwrap the optional data
            guard let data = document.data() else {
                throw MusterError.notFound("Muster with ID \(id) not found.")
            }

            // Parse data into Muster model
            guard let muster = Muster(from: data, id: document.documentID) else {
                throw MusterError.notFound("Invalid data for muster with ID \(id).")
            }

            return muster
        } catch let error as MusterError {
            throw error
        } catch {
            throw MusterError.notFound("Failed to fetch muster with ID \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - List Musters with Filters

    /// Lists musters based on optional filters.
    ///
    /// - Parameters:
    ///   - profileIds: An optional filter for profile IDs associated with the muster.
    ///   - primaryHospitalId: An optional filter for the primary hospital ID associated with the muster.
    ///   - administratorProfileIds: An optional filter for the administrator profile IDs.
    ///   - name: An optional filter for the muster name.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError.notFound`: If none are found or Firestore errors occur.
    @MainActor
    public func listMusters(
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil
    ) async throws -> [Muster] {
        do {
            var query: Query = await firestore.collection("Muster")

            if let profileIds = profileIds {
                query = query.whereField("profileIds", isEqualTo: profileIds)
            }
            if let primaryHospitalId = primaryHospitalId {
                query = query.whereField("primaryHospitalId", isEqualTo: primaryHospitalId)
            }
            if let administratorProfileIds = administratorProfileIds {
                query = query.whereField("administratorProfileIds", isEqualTo: administratorProfileIds)
            }
            if let name = name {
                query = query.whereField("name", isEqualTo: name)
            }

            // Fetch documents that match the query
            let snapshot = try await query.getDocuments()
            var musters = snapshot.documents.compactMap {
                Muster(from: $0.data(), id: $0.documentID)
            }

            // Manually filter by `profileIds` if provided (if your query logic requires it)
            if let profileIds = profileIds {
                musters = musters.filter { muster in
                    // Ensure that for each ID in `profileIds`, `muster.profileIds` contains that ID
                    profileIds.allSatisfy { muster.profileIds.contains($0) }
                }
            }

            return musters
        } catch {
            throw MusterError.notFound("Failed to fetch musters: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete an Existing Muster Record

    /// Deletes an existing muster record from Firestore.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.deletionFailed`: If an error occurs while deleting the muster.
    @MainActor
    public func deleteMuster(muster: Muster) async throws {
        do {
            try await firestore.collection("Muster").document(muster.id).delete()
        } catch {
            throw MusterError.deletionFailed("Failed to delete muster: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Invite a User to a Muster
    
    /// Sends a profile an invite to join a muster.
    ///
    /// - Parameter invite: The `MusterInvite` object defining the invitation.
    /// - Parameter userId: The ID of the user being invited.
    /// - Throws: `MusterError.invitationFailed` if sending fails.
    @MainActor
    public func sendMusterInvite(invite: MusterInvite, userId: String) async throws {
        do {
            let data = invite.dictionary
            try await firestore.collection("MusterInvite").document(invite.id).setData(data)
        } catch {
            throw MusterError.invitationFailed(error.localizedDescription)
        }
    }

    /// Collects all muster invitations for a user.
    ///
    /// - Parameter userId: The user ID associated with potential muster invites.
    /// - Returns: An array of `MusterInvite` objects for the specified user.
    /// - Throws: `MusterError.failedToCollectInvitations` if fetching fails.
    @MainActor
    public func collectUserMusterInvites(userId: String) async throws -> [MusterInvite] {
        do {
            let query = await firestore.collection("MusterInvite").whereField("recipientId", isEqualTo: userId)
            let snapshot = try await query.getDocuments()
            let invitations = snapshot.documents.compactMap {
                MusterInvite(from: $0.data(), id: $0.documentID)
            }
            return invitations
        } catch {
            throw MusterError.failedToCollectInvitations(error.localizedDescription)
        }
    }

    /// Collects all muster invitations for a specific muster.
    ///
    /// - Parameter musterId: The ID of the muster whose invitations should be fetched.
    /// - Returns: An array of `MusterInvite` objects for the specified muster.
    /// - Throws: `MusterError.failedToCollectInvitations` if fetching fails.
    @MainActor
    public func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite] {
        do {
            let query = await firestore.collection("MusterInvite").whereField("musterId", isEqualTo: musterId)
            let snapshot = try await query.getDocuments()
            let invitations = snapshot.documents.compactMap {
                MusterInvite(from: $0.data(), id: $0.documentID)
            }
            return invitations
        } catch {
            throw MusterError.failedToCollectInvitations(error.localizedDescription)
        }
    }

    /// Deletes all muster invitations associated with a given muster.
    ///
    /// - Parameter musterId: The ID of the muster whose invitations should be deleted.
    /// - Throws: `MusterError.failedToCollectInvitations` if fetching fails, or other errors during deletion.
    @MainActor
    public func deleteMusterInvites(musterId: String) async throws {
        let query = await firestore.collection("MusterInvite").whereField("musterId", isEqualTo: musterId)
        let snapshot = try await query.getDocuments()
        let invitations = snapshot.documents.compactMap {
            MusterInvite(from: $0.data(), id: $0.documentID)
        }
        
        for musterInvite in invitations {
            try await firestore.collection("MusterInvite").document(musterInvite.id).delete()
        }
    }

    /// Cancels a previously sent muster invitation by deleting its Firestore document.
    ///
    /// - Parameter invitationId: The ID of the invitation to cancel.
    /// - Throws: `MusterError.failedToCancelInvite` if deletion fails.
    @MainActor
    public func cancelMusterInvite(invitationId: String) async throws {
        do {
            try await firestore.collection("MusterInvite").document(invitationId).delete()
        } catch {
            throw MusterError.failedToCancelInvite(error.localizedDescription)
        }
    }
}
