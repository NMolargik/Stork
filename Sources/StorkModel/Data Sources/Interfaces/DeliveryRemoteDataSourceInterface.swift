//
//  DeliveryRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the interface for remote data source interactions related to deliveries.
public protocol DeliveryRemoteDataSourceInterface {
    /// Creates a new delivery record and returns the newly created `Delivery`.
    ///
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Returns: The newly created `Delivery`.
    /// - Throws: `DeliveryError` if the creation fails.
    func createDelivery(delivery: Delivery) async throws -> Delivery

    /// Updates an existing delivery record and returns the updated `Delivery`.
    ///
    /// - Parameter delivery: The `Delivery` object containing the updated data.
    /// - Returns: The updated `Delivery`.
    /// - Throws: `DeliveryError` if the update fails or the delivery does not exist.
    func updateDelivery(delivery: Delivery) async throws -> Delivery

    /// Retrieves a single delivery by its unique ID.
    ///
    /// - Parameter id: The unique ID of the delivery to fetch.
    /// - Returns: A `Delivery` object representing the delivery with the specified ID.
    /// - Throws: `DeliveryError` if the delivery cannot be found or another error occurs.
    func getDelivery(byId id: String) async throws -> Delivery

    /// Lists deliveries based on optional filters (including **date range** and **limit** for pagination).
    ///
    /// - Parameters:
    ///   - userId: An optional filter for the user ID associated with the delivery.
    ///   - userFirstName: An optional filter for the first name of the user.
    ///   - hospitalId: An optional filter for the hospital ID.
    ///   - hospitalName: An optional filter for the hospital name.
    ///   - musterId: An optional filter for the muster ID.
    ///   - date: An optional filter for a specific delivery date.
    ///   - babyCount: An optional filter for the number of babies in the delivery.
    ///   - deliveryMethod: An optional filter (e.g., vaginal, c-section).
    ///   - epiduralUsed: An optional filter for whether an epidural was used.
    ///   - startAt: (Pagination) An optional start date/time for the query. If provided, only deliveries on/after this date are included.
    ///   - endAt: (Pagination) An optional end date/time for the query. If provided, only deliveries before this date are included.
    ///
    /// - Returns: An array of `Delivery` objects matching the specified filters.
    /// - Throws: `DeliveryError` if the operation fails (e.g., connectivity issues).
    ///
    /// - Note: If both `startAt` and `endAt` are provided, only deliveries in `[startAt, endAt)` are returned.
    ///         If `limit` is provided, it restricts the maximum documents returned (like a page size).
    ///         You can combine these parameters to implement custom pagination schemes (e.g., 6-month intervals).
    func listDeliveries(
        userId: String?,
        userFirstName: String?,
        hospitalId: String?,
        hospitalName: String?,
        musterId: String?,
        date: Date?,
        babyCount: Int?,
        deliveryMethod: DeliveryMethod?,
        epiduralUsed: Bool?,
        startAt: Date?,        // Added for date-based pagination
        endAt: Date?          // Added for date-based pagination
    ) async throws -> [Delivery]

    /// Deletes an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError` if the deletion fails or the delivery does not exist.
    func deleteDelivery(delivery: Delivery) async throws
}
