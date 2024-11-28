//
//  MusterRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the interface for remote data source interactions related to musters.
public protocol MusterRemoteDataSourceInterface {
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
    ///   - id: An optional filter for the muster ID. If nil, this filter is ignored.
    ///   - profileIds: An optional filter for profile IDs associated with the muster. If nil, this filter is ignored.
    ///   - primaryHospitalId: An optional filter for the primary hospital ID associated with the muster. If nil, this filter is ignored.
    ///   - administratorProfileIds: An optional filter for the administrator profile ID. If nil, this filter is ignored.
    ///   - name: An optional filter for the muster name. If nil, this filter is ignored.
    ///   - primaryColor: An optional filter for the muster’s primary color. If nil, this filter is ignored.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws: `MusterError` if the operation fails or no musters are found.
    func listMusters(
        id: String?,
        profileIds: [String]?,
        primaryHospitalId: String?,
        administratorProfileIds: [String]?,
        name: String?,
        primaryColor: String?
    ) async throws -> [Muster]

    /// Creates a new muster record.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation fails.
    ///   - `MusterError.firebaseError`: If the Firestore operation fails.
    func createMuster(_ muster: Muster) async throws

    /// Updates an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object containing the updated data.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - `MusterError.firebaseError`: If the Firestore operation fails.
    func updateMuster(_ muster: Muster) async throws

    /// Deletes an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.deletionFailed`: If the deletion operation fails.
    ///   - `MusterError.firebaseError`: If the Firestore operation fails.
    func deleteMuster(_ muster: Muster) async throws
}
