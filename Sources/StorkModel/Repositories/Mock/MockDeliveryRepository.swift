//
//  MockDeliveryRepository.swift
//
//
//  Created by Nick Molargik on 11/20/24.
//

import Foundation

/// A mock implementation of the `DeliveryRepositoryInterface` protocol for testing purposes.
public class MockDeliveryRepository: DeliveryRepositoryInterface {
    // MARK: - Properties

    /// A list of mock deliveries used for in-memory storage.
    var deliveries: [Delivery]

    // MARK: - Initializer

    /// Initializes the mock repository with optional sample data.
    ///
    /// - Parameter deliveries: An array of `Delivery` objects to initialize the repository with.
    ///   Defaults to a single sample delivery.
    public init(deliveries: [Delivery] = []) {
        if deliveries.isEmpty {
            self.deliveries = [MockDeliveryRepository.createSampleDelivery()]
        } else {
            self.deliveries = deliveries
        }
    }
    

    // MARK: - Methods

    /// Creates a sample delivery with three babies.
    ///
    /// - Returns: A sample `Delivery` object.
    private static func createSampleDelivery() -> Delivery {
        let deliveryId = UUID().uuidString
        let hospitalId = UUID().uuidString
        let musterId = UUID().uuidString
        let date = Date()

        let babies = [
            Baby(deliveryId: deliveryId, nurseCatch: true, sex: Sex.male),
            Baby(deliveryId: deliveryId, nurseCatch: false, sex: Sex.female),
            Baby(deliveryId: deliveryId, nurseCatch: true, sex: Sex.loss)
        ]

        return Delivery(
            id: deliveryId,
            hospitalId: hospitalId,
            musterId: musterId,
            date: date,
            babies: babies,
            babyCount: babies.count,
            deliveryMethod: DeliveryMethod.vaginal,
            epiduralUsed: true
        )
    }

    /// Fetches a delivery by its unique ID.
    ///
    /// - Parameter id: The unique ID of the delivery.
    /// - Returns: A `Delivery` object matching the ID.
    /// - Throws: `DeliveryError.notFound` if no delivery with the specified ID exists.
    public func getDelivery(byId id: String) async throws -> Delivery? {
        guard let delivery = deliveries.first(where: { $0.id == id }) else {
            throw DeliveryError.notFound("Delivery with ID \(id) not found.")
        }
        return delivery
    }

    /// Lists deliveries based on optional filters.
    ///
    /// - Parameters:
    ///   - id: An optional delivery ID filter.
    ///   - hospitalId: An optional hospital ID filter.
    ///   - musterId: An optional muster ID filter.
    ///   - date: An optional date filter.
    ///   - babyCount: An optional baby count filter.
    ///   - deliveryMethod: An optional delivery method filter.
    ///   - epiduralUsed: An optional epidural usage filter.
    /// - Returns: A list of `Delivery` objects matching the filters.
    public func listDeliveries(
        id: String?,
        hospitalId: String?,
        musterId: String?,
        date: Date?,
        babyCount: Int?,
        deliveryMethod: DeliveryMethod?,
        epiduralUsed: Bool?
    ) async throws -> [Delivery] {
        return deliveries.filter { delivery in
            (id == nil || delivery.id == id) &&
            (hospitalId == nil || delivery.hospitalId == hospitalId) &&
            (musterId == nil || delivery.musterId == musterId) &&
            (date == nil || Calendar.current.isDate(delivery.date, inSameDayAs: date!)) &&
            (babyCount == nil || delivery.babies.count == babyCount) &&
            (deliveryMethod == nil || delivery.deliveryMethod == deliveryMethod) &&
            (epiduralUsed == nil || delivery.epiduralUsed == epiduralUsed)
        }
    }

    /// Creates a new delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Throws: `DeliveryError.creationFailed` if a delivery with the same ID already exists.
    public func createDelivery(_ delivery: Delivery) async throws {
        if deliveries.contains(where: { $0.id == delivery.id }) {
            throw DeliveryError.creationFailed("Delivery with ID \(delivery.id) already exists.")
        }
        deliveries.append(delivery)
    }

    /// Updates an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to update.
    /// - Throws: `DeliveryError.notFound` if the delivery does not exist.
    public func updateDelivery(_ delivery: Delivery) async throws {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.notFound("Delivery with ID \(delivery.id) not found.")
        }
        deliveries[index] = delivery
    }

    /// Deletes an existing delivery record.
    ///
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError.deletionFailed` if the delivery does not exist.
    public func deleteDelivery(_ delivery: Delivery) async throws {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.deletionFailed("Failed to delete delivery with ID \(delivery.id).")
        }
        deliveries.remove(at: index)
    }
}
