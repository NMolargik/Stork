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

    /// Initializes the repository with a remote data source.
    ///
    /// - Parameter remoteDataSource: An instance of `DeliveryRemoteDataSourceInterface`.
    public init(remoteDataSource: DeliveryRemoteDataSourceInterface) {
        self.remoteDataSource = remoteDataSource
    }
    
    // MARK: - Create

    /// Creates a new delivery record and returns the newly created `Delivery`.
    ///
    /// - Parameter delivery: The `Delivery` object to be created.
    /// - Returns: The newly created `Delivery`, including its Firestore-generated `id`.
    /// - Throws:
    ///   - `DeliveryError.creationFailed`: If the operation fails to create the delivery.
    public func createDelivery(delivery: Delivery) async throws -> Delivery {
        do {
            let createdDelivery = try await remoteDataSource.createDelivery(delivery: delivery)
            return createdDelivery
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.creationFailed("Failed to create delivery: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    /// Updates an existing delivery record and returns the updated `Delivery`.
    ///
    /// - Parameter delivery: The `Delivery` object containing the updated data.
    /// - Returns: The updated `Delivery`.
    /// - Throws:
    ///   - `DeliveryError.updateFailed`: If the operation fails to update the delivery.
    public func updateDelivery(delivery: Delivery) async throws -> Delivery {
        do {
            let updatedDelivery = try await remoteDataSource.updateDelivery(delivery: delivery)
            return updatedDelivery
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.updateFailed("Failed to update delivery: \(error.localizedDescription)")
        }
    }

    // MARK: - Read

    /// Fetches a single delivery by its unique ID.
    ///
    /// - Parameter id: The unique ID of the delivery to fetch.
    /// - Returns: A `Delivery` object representing the fetched delivery.
    /// - Throws:
    ///   - `DeliveryError.notFound`: If the delivery with the specified ID is not found.
    ///   - `DeliveryError.firebaseError`: If the operation fails due to a Firestore-related issue.
    public func getDelivery(byId id: String) async throws -> Delivery {
        do {
            return try await remoteDataSource.getDelivery(byId: id)
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.notFound("Failed to fetch delivery with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Lists deliveries based on optional filter criteria **and optional pagination parameters**.
    ///
    /// - Parameters:
    ///   - userId: An optional filter for the ID of the user associated with the delivery.
    ///   - userFirstName: An optional filter for the first name of the user.
    ///   - hospitalId: An optional filter for the hospital ID associated with the delivery.
    ///   - hospitalName: An optional filter for the hospital name.
    ///   - musterId: An optional filter for the muster ID associated with the delivery.
    ///   - date: An optional filter for the delivery date.
    ///   - babyCount: An optional filter for the number of babies in the delivery.
    ///   - deliveryMethod: An optional filter for the delivery method (e.g., vaginal, c-section).
    ///   - epiduralUsed: An optional filter for whether an epidural was used.
    ///   - startAt: An optional start date/time for the query (for pagination).
    ///   - endAt: An optional end date/time for the query (for pagination).
    ///
    /// - Returns: An array of `Delivery` objects matching the specified filters.
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If the operation fails due to a Firestore-related issue.
    ///
    /// - Note: Existing code can omit `startAt`, `endAt`, and `limit` to continue using the old behavior.
    public func listDeliveries(
        userId: String? = nil,
        userFirstName: String? = nil,
        hospitalId: String? = nil,
        hospitalName: String? = nil,
        musterId: String? = nil,
        date: Date? = nil,
        babyCount: Int? = nil,
        deliveryMethod: DeliveryMethod? = nil,
        epiduralUsed: Bool? = nil,
        startAt: Date? = nil,  // ✅ New optional parameter
        endAt: Date? = nil    // ✅ New optional parameter
    ) async throws -> [Delivery] {
        do {
            return try await remoteDataSource.listDeliveries(
                userId: userId,
                userFirstName: userFirstName,
                hospitalId: hospitalId,
                hospitalName: hospitalName,
                musterId: musterId,
                date: date,
                babyCount: babyCount,
                deliveryMethod: deliveryMethod,
                epiduralUsed: epiduralUsed,
                startAt: startAt,   // ✅ Pass through
                endAt: endAt       // ✅ Pass through
            )
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.firebaseError("Failed to list deliveries: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    /// Deletes an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to be deleted.
    /// - Throws:
    ///   - `DeliveryError.deletionFailed`: If the operation fails to delete the delivery.
    public func deleteDelivery(delivery: Delivery) async throws {
        do {
            try await remoteDataSource.deleteDelivery(delivery: delivery)
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.deletionFailed("Failed to delete delivery: \(error.localizedDescription)")
        }
    }
}
