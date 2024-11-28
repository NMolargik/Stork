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

    /// Fetches a single muster by its unique ID.
    ///
    /// - Parameter id: The unique ID of the muster to fetch.
    /// - Returns: A `Muster` object representing the fetched muster.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster with the specified ID does not exist.
    ///   - `MusterError`: For other failures during the fetch operation.
    public func getMuster(byId id: String) async throws -> Muster {
        return try await remoteDataSource.getMuster(byId: id)
    }

    /// Lists musters based on optional filter criteria.
    ///
    /// - Parameters:
    ///   - id: An optional filter for the muster ID.
    ///   - profileIds: An optional filter for profile IDs associated with the muster.
    ///   - primaryHospitalId: An optional filter for the hospital id associated with the muster
    ///   - name: An optional filter for the muster name.
    ///   - administratorProfileId: An optional filter for the administrator's profile ID.
    ///   - primaryColor: An optional filter for the muster’s primary color.
    /// - Returns: An array of `Muster` objects matching the specified filters.
    /// - Throws:
    ///   - `MusterError`: For failures during the fetch operation.
    public func listMusters(
        id: String? = nil,
        profileIds: [String]? = nil,
        primaryHospitalId: String? = nil,
        administratorProfileIds: [String]? = nil,
        name: String? = nil,
        primaryColor: String? = nil
    ) async throws -> [Muster] {
        return try await remoteDataSource.listMusters(
            id: id,
            profileIds: profileIds,
            primaryHospitalId: primaryHospitalId,
            administratorProfileIds: administratorProfileIds,
            name: name,
            primaryColor: primaryColor
        )
    }

    /// Creates a new muster record.
    ///
    /// - Parameter muster: The `Muster` object to create.
    /// - Throws:
    ///   - `MusterError.creationFailed`: If the creation operation fails.
    ///   - `MusterError`: For other failures during the creation operation.
    public func createMuster(_ muster: Muster) async throws {
        try await remoteDataSource.createMuster(muster)
    }

    /// Updates an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object containing updated data.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.updateFailed`: If the update operation fails.
    ///   - `MusterError`: For other failures during the update operation.
    public func updateMuster(_ muster: Muster) async throws {
        try await remoteDataSource.updateMuster(muster)
    }
    
    /// Deletes an existing muster record.
    ///
    /// - Parameter muster: The `Muster` object to delete.
    /// - Throws:
    ///   - `MusterError.notFound`: If the muster does not exist.
    ///   - `MusterError.deletionFailed`: If the deletion operation fails.
    ///   - `MusterError`: For other failures during the deletion operation.
    public func deleteMuster(_ muster: Muster) async throws {
        try await remoteDataSource.deleteMuster(muster)
    }
}
