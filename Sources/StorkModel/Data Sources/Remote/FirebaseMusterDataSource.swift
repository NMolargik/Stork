//
//  FirebaseMusterDataSource.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
#if SKIP
import SkipFirebaseFirestore
#else
import FirebaseFirestore
#endif

/// A data source responsible for interacting with the Firebase Firestore database to manage muster records.
public class FirebaseMusterDataSource: MusterRemoteDataSourceInterface {
    /// The Firestore database instance.
    private let db: Firestore

    /// Initializes the FirebaseMusterDataSource with a Firestore instance.
    public init() {
        self.db = Firestore.firestore()
    }

    // MARK: - Create a New Muster Record

    /// Creates a new muster record in Firestore.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Returns: The same 'Muster' object to confirm creation
    /// - Throws:
    ///   - `MusterError.firebaseError`: If an error occurs while creating the muster.
    public func createMuster(muster: Muster) async throws {
        do {
            print(muster.id)
            let data = muster.dictionary
            try await db.collection("Muster").document(muster.id).setData(data)
        } catch {
            throw MusterError.creationFailed("Failed to create muster: \(error.localizedDescription)")
        }
    }

    // MARK: - Update an Existing Muster Record

    /// Updates an existing muster record in Firestore.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Throws:
    ///   - `MusterError.firebaseError`: If an error occurs while updating the muster.
    public func updateMuster(muster: Muster) async throws {
        do {
            let data = muster.dictionary
            try await db.collection("Muster").document(muster.id).updateData(data)
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
    public func getMuster(byId id: String) async throws -> Muster {
        do {
            print("MusterId: \(id)")
            let document = try await db.collection("Muster").document(id).getDocument()

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
    ///   - primaryColor: An optional filter for the muster’s primary color.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError.firebaseError`: If an error occurs while fetching the musters.
    public func listMusters(
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil,
        primaryColor: String? = nil
    ) async throws -> [Muster] {
        do {
            var query: Query = db.collection("Muster")

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
            if let primaryColor = primaryColor {
                query = query.whereField("primaryColor", isEqualTo: primaryColor)
            }

            // Fetch documents that match the query
            let snapshot = try await query.getDocuments()
            var musters = snapshot.documents.compactMap { document in
                Muster(from: document.data(), id: document.documentID)
            }

            // Manually filter by `profileIds` if provided
            if let profileIds = profileIds {
                musters = musters.filter { muster in
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
    ///   - `MusterError.firebaseError`: If an error occurs while deleting the muster.
    public func deleteMuster(muster: Muster) async throws {
        do {
            try await db.collection("Muster").document(muster.id).delete()
        } catch {
            throw MusterError.deletionFailed("Failed to delete muster: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Invite a user to a muster
    
    /// Sends a profile an invite to join a muster
    ///
    /// - Parameter invite: The `MusterInvite` object defining the invitation
    /// - Parameter userId: The id of the user that is being invited
    /// - Throws:
    public func sendMusterInvite(invite: MusterInvite, userId: String) async throws {
        do {
            let data = invite.dictionary
            try await db.collection("MusterInvite").document(invite.id).setData(data)

        } catch {
            throw MusterError.invitationFailed(error.localizedDescription)
        }
    }
    
    public func collectUserMusterInvites(userId: String) async throws -> [MusterInvite] {
        do {
            let query: Query = db.collection("MusterInvite").whereField("recipientId", isEqualTo: userId)

            // Fetch documents that match the query
            let snapshot = try await query.getDocuments()
            let invitations = snapshot.documents.compactMap { document in
                MusterInvite(from: document.data(), id: document.documentID)
            }

            return invitations
        } catch {
            throw MusterError.failedToCollectInvitations(error.localizedDescription)
        }
    }
    
    public func collectInvitesForMuster(musterId: String) async throws -> [MusterInvite] {
        do {
            let query: Query = db.collection("MusterInvite").whereField("musterId", isEqualTo: musterId)
            
            let snapshot = try await query.getDocuments()
            let invitations = snapshot.documents.compactMap { document in
                MusterInvite(from: document.data(), id: document.documentID)
            }
            
            return invitations
        } catch {
            throw MusterError.failedToCollectInvitations(error.localizedDescription)
        }
    }
    
    public func deleteMusterInvites(musterId: String) async throws {
        let query: Query = db.collection("MusterInvite").whereField("musterId", isEqualTo: musterId)
        
        let snapshot = try await query.getDocuments()
        let invitations = snapshot.documents.compactMap { document in
            MusterInvite(from: document.data(), id: document.documentID)
        }
        
        for musterInvite in invitations {
            try await db.collection("MusterInvite").document(musterInvite.id).delete()
        }
    }
    
    public func cancelMusterInvite(invitationId: String) async throws {
        do {
            try await db.collection("MusterInvite").document(invitationId).delete()
        } catch {
            throw MusterError.failedToCancelInvite(error.localizedDescription)
        }
    }
}
