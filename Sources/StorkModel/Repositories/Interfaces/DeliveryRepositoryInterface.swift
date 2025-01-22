//
//  DeliveryRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

public protocol DeliveryRepositoryInterface {
    /// Creates a new delivery record.
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Returns: The newly created `Delivery` (including its generated ID).
    /// - Throws: `DeliveryError` if the creation fails.
    func createDelivery(delivery: Delivery) async throws -> Delivery

    /// Updates an existing delivery record.
    /// - Parameter delivery: The `Delivery` object to update.
    /// - Returns: The updated `Delivery`.
    /// - Throws: `DeliveryError` if the update fails.
    func updateDelivery(delivery: Delivery) async throws -> Delivery

    /// Fetches a delivery by its unique ID.
    /// - Parameter id: The unique ID of the delivery.
    /// - Returns: A `Delivery` object for the specified ID.
    /// - Throws: `DeliveryError.notFound` if the delivery cannot be found.
    ///           Other `DeliveryError` if the fetch fails.
    func getDelivery(byId id: String) async throws -> Delivery

    /// Lists deliveries based on optional filters **and optional pagination parameters**.
    /// - Parameters:
    ///   - userId: An optional filter for the ID of the user associated with the delivery.
    ///   - userFirstName: An optional filter for the first name of the user.
    ///   - hospitalId: An optional hospital ID filter.
    ///   - hospitalName: An optional hospital name filter.
    ///   - musterId: An optional muster ID filter.
    ///   - date: An optional date filter (for a specific day).
    ///   - babyCount: An optional baby count filter.
    ///   - deliveryMethod: An optional delivery method filter (e.g., vaginal, c-section).
    ///   - epiduralUsed: An optional epidural usage filter.
    ///   - startAt: (Pagination) An optional start date/time for the query.
    ///   - endAt: (Pagination) An optional end date/time for the query.
    /// - Returns: A list of `Delivery` objects matching the filters.
    /// - Throws: `DeliveryError` if the query fails.
    ///
    /// **Backward compatibility**: Existing code can omit `startAt`, `endAt`, and `limit`
    /// to continue using the old behavior.
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
        startAt: Date?,   // New optional date-based pagination
        endAt: Date?     // New optional date-based pagination
    ) async throws -> [Delivery]

    /// Deletes an existing delivery record.
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError` if the deletion fails.
    func deleteDelivery(delivery: Delivery) async throws
}
