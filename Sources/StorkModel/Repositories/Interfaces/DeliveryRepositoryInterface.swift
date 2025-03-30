//
//  DeliveryRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation
import Foundation

/// A protocol defining the interface for accessing delivery data.
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

    /// Lists deliveries based on optional filters, supporting **6-month interval pagination**.
    ///
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
    ///   - startDate: (Pagination) The **start date of the 6-month range**.
    ///   - endDate: (Pagination) The **end date of the 6-month range**.
    ///
    /// - Returns: A list of `Delivery` objects matching the filters within the specified 6-month period.
    /// - Throws: `DeliveryError` if the query fails.
    ///
    /// **Pagination Behavior:**
    /// - If `startDate` and `endDate` are both provided, only deliveries **between** those dates will be returned.
    /// - If only `startDate` is provided, results will include deliveries **from that date onward**.
    /// - If only `endDate` is provided, results will include deliveries **before that date**.
    /// - If neither is provided, the **most recent 6-month interval** will be used.
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
        startDate: Date?,   // Updated to match Firestore logic
        endDate: Date?      // Updated to match Firestore logic
    ) async throws -> [Delivery]

    /// Deletes an existing delivery record.
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError` if the deletion fails.
    func deleteDelivery(delivery: Delivery) async throws
}
