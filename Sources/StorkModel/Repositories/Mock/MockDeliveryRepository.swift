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
                        nicuStay: true,
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

    public func createDelivery(delivery: Delivery) async throws -> Delivery {
        if deliveries.contains(where: { $0.id == delivery.id }) {
            throw DeliveryError.creationFailed("Delivery with ID \(delivery.id) already exists.")
        }
        deliveries.append(delivery)
        return delivery
    }

    public func updateDelivery(delivery: Delivery) async throws -> Delivery {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.notFound("Delivery with ID \(delivery.id) not found.")
        }
        deliveries[index] = delivery
        return delivery
    }

    public func getDelivery(byId id: String) async throws -> Delivery {
        guard let delivery = deliveries.first(where: { $0.id == id }) else {
            throw DeliveryError.notFound("Delivery with ID \(id) not found.")
        }
        return delivery
    }

    // MARK: - List Deliveries (6-Month Pagination)

    /// Lists deliveries based on optional filter criteria **and** 6-month pagination.
    ///
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
    ///   - startDate: (Pagination) The **start date of the 6-month range**.
    ///   - endDate: (Pagination) The **end date of the 6-month range**.
    ///
    /// - Returns: An array of `Delivery` objects matching the specified filters within the given 6-month period.
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
        startDate: Date? = nil,   // ✅ Updated parameter name
        endDate: Date? = nil      // ✅ Updated parameter name
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

        // 2) Apply 6-month pagination filters
        if let startDate {
            filtered = filtered.filter { $0.date >= startDate }
        }
        if let endDate {
            filtered = filtered.filter { $0.date < endDate }
        }

        // Return filtered deliveries
        return filtered
    }

    public func deleteDelivery(delivery: Delivery) async throws {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.deletionFailed("Failed to delete delivery with ID \(delivery.id).")
        }
        deliveries.remove(at: index)
    }
}
