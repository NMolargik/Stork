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

    // MARK: - Retrieve a Single Muster by ID

    /// Fetches a single muster by its unique ID.
    ///
    /// - Parameter id: The unique ID of the muster to fetch.
    /// - Returns: A `Muster` object representing the muster with the specified ID.
    /// - Throws:
    ///   - `MusterError.notFound`: If no muster with the specified ID is found.
    ///   - `MusterError.firebaseError`: If an error occurs while fetching the muster.
    public func getMuster(byId id: String) async throws -> Muster {
        do {
            let document = try await db.collection("Muster").document(id).getDocument()

            // Safely unwrap the optional data
            guard let data = document.data() else {
                throw MusterError.notFound("Muster with ID \(id) not found.")
            }

            // Parse data into Muster model
            guard let muster = Muster(from: data) else {
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
    ///   - id: An optional filter for the muster ID.
    ///   - profileIds: An optional filter for profile IDs associated with the muster.
    ///   - primaryHospitalId: An optional filter for the primary hospital ID associated with the muster.
    ///   - administratorProfileIds: An optional filter for the administrator profile IDs.
    ///   - name: An optional filter for the muster name.
    ///   - primaryColor: An optional filter for the muster’s primary color.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError.firebaseError`: If an error occurs while fetching the musters.
    public func listMusters(
        id: String? = nil,
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil,
        primaryColor: String? = nil
    ) async throws -> [Muster] {
        do {
            var query: Query = db.collection("Muster")

            // Apply optional filters to the query
            if let id = id {
                query = query.whereField("id", isEqualTo: id)
            }
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
                Muster(from: document.data())
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

    // MARK: - Create a New Muster Record

    /// Creates a new muster record in Firestore.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Throws:
    ///   - `MusterError.firebaseError`: If an error occurs while creating the muster.
    public func createMuster(_ muster: Muster) async throws {
        do {
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
    public func updateMuster(_ muster: Muster) async throws {
        do {
            let data = muster.dictionary
            try await db.collection("Muster").document(muster.id).updateData(data)
        } catch {
            throw MusterError.updateFailed("Failed to update muster: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete an Existing Muster Record

    /// Deletes an existing muster record from Firestore.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.firebaseError`: If an error occurs while deleting the muster.
    public func deleteMuster(_ muster: Muster) async throws {
        do {
            try await db.collection("Muster").document(muster.id).delete()
        } catch {
            throw MusterError.deletionFailed("Failed to delete muster: \(error.localizedDescription)")
        }
    }
}
