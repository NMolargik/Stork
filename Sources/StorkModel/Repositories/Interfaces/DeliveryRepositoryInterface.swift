//
//  DeliveryRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

public protocol DeliveryRepositoryInterface {
    /// Fetches a delivery by its unique ID.
    /// - Parameter id: The unique ID of the delivery.
    /// - Returns: A `Delivery` object.
    /// - Throws: `DeliveryError` if the delivery cannot be fetched or does not exist.
    func getDelivery(byId id: String) async throws -> Delivery?

    /// Lists deliveries based on optional filters.
    /// - Parameters:
    ///   - userId: An optional filter for id of the user associated with the delivery
    ///   - userFirstName: An optional filter for first name of the user associated with the delivery
    ///   - hospitalId: An optional hospital ID filter.
    ///   - musterId: An optional muster ID filter.
    ///   - date: An optional date filter.
    ///   - babyCount: An optional baby count filter.
    ///   - deliveryMethod: An optional delivery method filter.
    ///   - epiduralUsed: An optional epidural usage filter.
    /// - Returns: A list of `Delivery` objects matching the filters.
    /// - Throws: `DeliveryError` if the query fails.
    func listDeliveries(
        userId: String?,
        userFirstName: String?,
        hospitalId: String?,
        musterId: String?,
        date: Date?,
        babyCount: Int?,
        deliveryMethod: DeliveryMethod?,
        epiduralUsed: Bool?
    ) async throws -> [Delivery]

    /// Creates a new delivery record.
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Returns: The same `Delivery` object with a new ID
    /// - Throws: `DeliveryError` if the creation fails.
    func createDelivery(_ delivery: Delivery) async throws -> Delivery

    /// Updates an existing delivery record.
    /// - Parameter delivery: The `Delivery` object to update.
    /// - Throws: `DeliveryError` if the update fails.
    func updateDelivery(_ delivery: Delivery) async throws

    /// Deletes an existing delivery record.
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError` if the deletion fails.
    func deleteDelivery(_ delivery: Delivery) async throws
}
