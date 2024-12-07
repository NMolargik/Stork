//
//  DefaultDeliveryRepository.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A concrete implementation of the `DeliveryRepositoryInterface` protocol.
/// This class is responsible for handling delivery-related operations by interacting with a remote data source.
public class DefaultDeliveryRepository: DeliveryRepositoryInterface {
    // MARK: - Properties

    /// The remote data source used to perform delivery operations.
    private let remoteDataSource: DeliveryRemoteDataSourceInterface

    // MARK: - Initializer

    /// Initializes the `DefaultDeliveryRepository` with a specified remote data source.
    ///
    /// - Parameter remoteDataSource: The remote data source implementing `DeliveryRemoteDataSourceInterface`.
    public init(remoteDataSource: DeliveryRemoteDataSourceInterface) {
        self.remoteDataSource = remoteDataSource
    }

    // MARK: - Methods

    /// Fetches a single delivery by its unique ID.
    ///
    /// - Parameter id: The unique ID of the delivery to fetch.
    /// - Returns: A `Delivery` object representing the fetched delivery.
    /// - Throws:
    ///   - `DeliveryError.notFound`: If the delivery with the specified ID is not found.
    ///   - `DeliveryError.firebaseError`: If the operation fails due to a Firestore-related issue.
    public func getDelivery(byId id: String) async throws -> Delivery? {
        do {
            return try await remoteDataSource.getDelivery(byId: id)
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.notFound("Failed to fetch delivery with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Lists deliveries based on optional filter criteria.
    ///
    /// - Parameters:
    ///   - id: An optional filter for the delivery ID.
    ///   - userId: An optional filter for id of the user associated with the delivery
    ///   - hospitalId: An optional filter for the hospital ID associated with the delivery.
    ///   - musterId: An optional filter for the muster ID associated with the delivery
    ///   - date: An optional filter for the delivery date.
    ///   - babyCount: An optional filter for the number of babies in the delivery.
    ///   - deliveryMethod: An optional filter for the delivery method (e.g., vaginal, c-section).
    ///   - epiduralUsed: An optional filter for whether an epidural was used.
    /// - Returns: An array of `Delivery` objects matching the specified filters.
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If the operation fails due to a Firestore-related issue.
    public func listDeliveries(
        id: String? = nil,
        userId: String? = nil,
        hospitalId: String? = nil,
        musterId: String? = nil,
        date: Date? = nil,
        babyCount: Int? = nil,
        deliveryMethod: DeliveryMethod? = nil,
        epiduralUsed: Bool? = nil
    ) async throws -> [Delivery] {
        do {
            return try await remoteDataSource.listDeliveries(
                id: id,
                userId: userId,
                hospitalId: hospitalId,
                musterId: musterId,
                date: date,
                babyCount: babyCount,
                deliveryMethod: deliveryMethod,
                epiduralUsed: epiduralUsed
            )
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.firebaseError("Failed to list deliveries: \(error.localizedDescription)")
        }
    }

    /// Creates a new delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to be created.
    /// - Throws:
    ///   - `DeliveryError.creationFailed`: If the operation fails to create the delivery.
    public func createDelivery(_ delivery: Delivery) async throws {
        do {
            try await remoteDataSource.createDelivery(delivery)
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.creationFailed("Failed to create delivery: \(error.localizedDescription)")
        }
    }

    /// Updates an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object containing the updated data.
    /// - Throws:
    ///   - `DeliveryError.updateFailed`: If the operation fails to update the delivery.
    public func updateDelivery(_ delivery: Delivery) async throws {
        do {
            try await remoteDataSource.updateDelivery(delivery)
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.updateFailed("Failed to update delivery: \(error.localizedDescription)")
        }
    }

    /// Deletes an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to be deleted.
    /// - Throws:
    ///   - `DeliveryError.deletionFailed`: If the operation fails to delete the delivery.
    public func deleteDelivery(_ delivery: Delivery) async throws {
        do {
            try await remoteDataSource.deleteDelivery(delivery)
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.deletionFailed("Failed to delete delivery: \(error.localizedDescription)")
        }
    }
}
