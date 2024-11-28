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
    ///   - id: An optional filter for the muster ID.
    ///   - profileIds: An optional filter for profile IDs associated with the muster.
    ///   - primaryHospitalId: An optional filter for hospital Id associated with the muster.
    ///   - administratorProfileIds: An optional filter for the administrators' profile IDs.
    ///   - name: An optional filter for the muster name.
    ///   - primaryColor: An optional filter for the muster’s primary color.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError`: If the operation fails or no matching Musters are found.
    func listMusters(
        id: String?,
        profileIds: [String]?,
        primaryHospitalId: String?,
        administratorProfileIds: [String]?,
        name: String?,
        primaryColor: String?
    ) async throws -> [Muster]

    /// Creates a new Muster record.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation fails.
    ///   - `MusterError`: For other failures during the creation.
    func createMuster(_ muster: Muster) async throws

    /// Updates an existing Muster record.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - `MusterError`: For other failures during the update.
    func updateMuster(_ muster: Muster) async throws

    /// Deletes an existing Muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.deletionFailed`: If the deletion operation fails.
    ///   - `MusterError`: For other failures during the deletion.
    func deleteMuster(_ muster: Muster) async throws
}
