//
//  DeliveryRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the interface for remote data source interactions related to deliveries.
public protocol DeliveryRemoteDataSourceInterface {
    /// Retrieves a single delivery by its unique ID.
    ///
    /// - Parameter id: The unique ID of the delivery to fetch.
    /// - Returns: A `Delivery` object representing the delivery with the specified ID.
    /// - Throws: `DeliveryError` if the delivery cannot be found or another error occurs.
    func getDelivery(byId id: String) async throws -> Delivery?

    /// Lists deliveries based on optional filters.
    ///
    /// - Parameters:
    ///   - id: An optional filter for the delivery ID. If nil, this filter is ignored.
    ///   - userId: An optional filter for id of the user associated with the delivery
    ///   - hospitalId: An optional filter for the hospital ID associated with the delivery. If nil, this filter is ignored.
    ///   - musterId: An optional filter for the muster ID associated with the delivery. If nil, this filter is ignored.
    ///   - date: An optional filter for the delivery date. If nil, this filter is ignored.
    ///   - babyCount: An optional filter for the number of babies in the delivery. If nil, this filter is ignored.
    ///   - deliveryMethod: An optional filter for the delivery method (e.g., vaginal, c-section). If nil, this filter is ignored.
    ///   - epiduralUsed: An optional filter for whether an epidural was used. If nil, this filter is ignored.
    /// - Returns: An array of `Delivery` objects matching the specified filters.
    /// - Throws: `DeliveryError` if the operation fails or no deliveries are found.
    func listDeliveries(
        id: String?,
        userId: String?,
        hospitalId: String?,
        musterId: String?,
        date: Date?,
        babyCount: Int?,
        deliveryMethod: DeliveryMethod?,
        epiduralUsed: Bool?
    ) async throws -> [Delivery]

    /// Creates a new delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Throws: `DeliveryError` if the creation fails.
    func createDelivery(_ delivery: Delivery) async throws

    /// Updates an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object containing the updated data.
    /// - Throws: `DeliveryError` if the update fails or the delivery does not exist.
    func updateDelivery(_ delivery: Delivery) async throws

    /// Deletes an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError` if the deletion fails or the delivery does not exist.
    func deleteDelivery(_ delivery: Delivery) async throws
}
