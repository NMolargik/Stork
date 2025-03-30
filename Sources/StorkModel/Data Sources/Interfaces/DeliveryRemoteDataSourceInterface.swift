//
//  DeliveryRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation
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

    /// Lists deliveries based on optional filters, supporting pagination in **6-month intervals**.
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
    ///   - startDate: (Pagination) The **start date of the 6-month range**. If provided, only deliveries on/after this date are included.
    ///   - endDate: (Pagination) The **end date of the 6-month range**. If provided, only deliveries before this date are included.
    ///
    /// - Returns: An array of `Delivery` objects matching the specified filters within the given 6-month range.
    /// - Throws: `DeliveryError` if the operation fails (e.g., connectivity issues).
    ///
    /// - Note:
    ///   - Pagination is based on **6-month intervals**, so each query fetches deliveries within a 6-month range.
    ///   - If both `startDate` and `endDate` are provided, only deliveries in `[startDate, endDate)` are returned.
    ///   - This approach allows users to **scroll through time-based groups** rather than arbitrary document limits.
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
        startDate: Date?,  // Defines the start of the 6-month range
        endDate: Date?     // Defines the end of the 6-month range
    ) async throws -> [Delivery]
    
    /// Deletes an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError` if the deletion fails or the delivery does not exist.
    func deleteDelivery(delivery: Delivery) async throws
}
