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
    ///   Defaults to multiple sample deliveries with associated babies.
    public init(deliveries: [Delivery] = []) {
        if deliveries.isEmpty {
            self.deliveries = MockDeliveryRepository.createSampleDeliveries()
        } else {
            self.deliveries = deliveries
        }
    }

    // MARK: - Helper: Create Sample Deliveries

    /// Creates multiple sample deliveries with random babies.
    ///
    /// - Returns: An array of `Delivery` objects.
    private static func createSampleDeliveries() -> [Delivery] {
        let calendar = Calendar.current
        let currentDate = Date()
        let deliveryMethods: [DeliveryMethod] = [.vaginal, .cSection, .vBac]

        var sampleDeliveries: [Delivery] = []

        // Generate deliveries for the last 6 months
        for monthOffset in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate) else {
                continue
            }
            // Randomize number of deliveries for each month
            let numberOfDeliveries = Int.random(in: 1...5)

            for _ in 0..<numberOfDeliveries {
                // Pick a random day in that month
                let randomDate: Date = {
                    var components = calendar.dateComponents([.year, .month], from: monthDate)
                    components.day = Int.random(in: 1...28)
                    return calendar.date(from: components) ?? monthDate
                }()

                let deliveryId = UUID().uuidString
                let userId = UUID().uuidString
                let babyCount = Int.random(in: 1...4)

                // Create babies for the delivery
                let babies = (0..<babyCount).map { _ in
                    Baby(
                        id: UUID().uuidString,
                        deliveryId: deliveryId,
                        birthday: randomDate,
                        height: Double.random(in: 17.0...22.0),
                        weight: Double.random(in: 5.0...9.0),
                        nurseCatch: true,
                        sex: .male
                    )
                }

                // Create the delivery
                let newDelivery = Delivery(
                    id: deliveryId,
                    userId: userId,
                    userFirstName: "FirstName",
                    hospitalId: UUID().uuidString,
                    hospitalName: "Parkview Regional Medical Center",
                    musterId: UUID().uuidString,
                    date: randomDate,
                    babies: babies,
                    babyCount: babies.count,
                    deliveryMethod: deliveryMethods.randomElement() ?? .vaginal,
                    epiduralUsed: true
                )

                sampleDeliveries.append(newDelivery)
            }
        }

        // Sort descending by date
        return sampleDeliveries.sorted { $0.date > $1.date }
    }

    // MARK: - CRUD Methods

    /// Creates a new delivery and returns the newly created `Delivery`.
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Returns: The newly created `Delivery`.
    /// - Throws: `DeliveryError.creationFailed` if a delivery with the same ID already exists.
    public func createDelivery(delivery: Delivery) async throws -> Delivery {
        if deliveries.contains(where: { $0.id == delivery.id }) {
            throw DeliveryError.creationFailed("Delivery with ID \(delivery.id) already exists.")
        }
        deliveries.append(delivery)
        return delivery
    }

    /// Updates an existing delivery and returns the updated `Delivery`.
    /// - Parameter delivery: The `Delivery` object with updated data.
    /// - Returns: The updated `Delivery`.
    /// - Throws: `DeliveryError.notFound` if no delivery with the given ID exists.
    public func updateDelivery(delivery: Delivery) async throws -> Delivery {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.notFound("Delivery with ID \(delivery.id) not found.")
        }
        deliveries[index] = delivery
        return delivery
    }

    /// Fetches a delivery by its unique ID.
    /// - Parameter id: The ID of the delivery to fetch.
    /// - Returns: A `Delivery` object matching the specified ID.
    /// - Throws: `DeliveryError.notFound` if no such delivery exists.
    public func getDelivery(byId id: String) async throws -> Delivery {
        guard let delivery = deliveries.first(where: { $0.id == id }) else {
            throw DeliveryError.notFound("Delivery with ID \(id) not found.")
        }
        return delivery
    }

    /// Lists deliveries based on optional filter criteria **and** optional pagination parameters.
    /// - Parameters:
    ///   - userId: Optional filter by user ID.
    ///   - userFirstName: Optional filter by the user's first name.
    ///   - hospitalId: Optional filter by hospital ID.
    ///   - hospitalName: Optional filter by hospital name.
    ///   - musterId: Optional filter by muster ID.
    ///   - date: Optional filter by exact date (same day).
    ///   - babyCount: Optional filter by baby count.
    ///   - deliveryMethod: Optional filter by delivery method.
    ///   - epiduralUsed: Optional filter by epidural usage.
    ///   - startAt: (Pagination) Optional start date/time; only returns deliveries on/after this date.
    ///   - endAt: (Pagination) Optional end date/time; only returns deliveries before this date.
    ///
    /// - Returns: An array of `Delivery` objects matching the specified filters.
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
        startAt: Date? = nil,   // ✅ New optional parameter
        endAt: Date? = nil     // ✅ New optional parameter
    ) async throws -> [Delivery] {
        // 1) Apply existing filters
        var filtered = deliveries.filter { delivery in
            (userId == nil || delivery.userId == userId) &&
            (userFirstName == nil || delivery.userFirstName == userFirstName) &&
            (hospitalId == nil || delivery.hospitalId == hospitalId) &&
            (hospitalName == nil || delivery.hospitalName == hospitalName) &&
            (musterId == nil || delivery.musterId == musterId) &&
            (date == nil || Calendar.current.isDate(delivery.date, inSameDayAs: date!)) &&
            (babyCount == nil || delivery.babies.count == babyCount) &&
            (deliveryMethod == nil || delivery.deliveryMethod == deliveryMethod) &&
            (epiduralUsed == nil || delivery.epiduralUsed == epiduralUsed)
        }

        // 2) Apply new date-based filters (pagination)
        if let startAt = startAt {
            filtered = filtered.filter { $0.date >= startAt }
        }
        if let endAt = endAt {
            filtered = filtered.filter { $0.date < endAt }
        }

        // Return the filtered/paginated deliveries
        return filtered
    }

    /// Deletes a delivery from the mock storage.
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws: `DeliveryError.deletionFailed` if the delivery cannot be found in the mock storage.
    public func deleteDelivery(delivery: Delivery) async throws {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.deletionFailed("Failed to delete delivery with ID \(delivery.id).")
        }
        deliveries.remove(at: index)
    }
}
