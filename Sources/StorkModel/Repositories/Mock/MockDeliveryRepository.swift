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

    // MARK: - Methods

    /// Creates multiple sample deliveries with random babies.
    ///
    /// - Returns: An array of `Delivery` objects.
    private static func createSampleDeliveries() -> [Delivery] {
        let calendar = Calendar.current
        let currentDate = Date()
        let deliveryMethods: [DeliveryMethod] = [.vaginal, .cSection, .vBac]

        var sampleDeliveries: [Delivery] = []

        for monthOffset in 0..<6 { // Generate deliveries for the last 6 months
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate) else { continue }
            let numberOfDeliveries = Int.random(in: 1...5) // Randomize number of deliveries per month

            for _ in 0..<numberOfDeliveries {
                let randomDate: Date = {
                    var components = Calendar.current.dateComponents([.year, .month], from: monthDate)
                    components.day = Int.random(in: 1...28) // Random day in the range
                    return Calendar.current.date(from: components) ?? monthDate
                }()
                
                // Generate delivery ID
                let deliveryId = UUID().uuidString
                
                // Generate user ID
                let userId = UUID().uuidString

                // Generate babies for the delivery
                let babyCount = Int.random(in: 1...4)
                let babies = (0..<babyCount).map { _ in
                    Baby(
                        id: UUID().uuidString,
                        deliveryId: deliveryId,
                        birthday: randomDate,
                        height: Double.random(in: 17.0...22.0), // Height in inches
                        weight: Double.random(in: 5.0...9.0),   // Weight in pounds
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
                    musterId: UUID().uuidString,
                    date: randomDate,
                    babies: babies,
                    babyCount: babies.count,
                    deliveryMethod: deliveryMethods.randomElement() ?? DeliveryMethod.vaginal,
                    epiduralUsed: true
                )

                sampleDeliveries.append(newDelivery)
            }
        }

        return sampleDeliveries.sorted { $0.date > $1.date }
    }

    // MARK: - CRUD Methods

    public func getDelivery(byId id: String) async throws -> Delivery? {
        guard let delivery = deliveries.first(where: { $0.id == id }) else {
            throw DeliveryError.notFound("Delivery with ID \(id) not found.")
        }
        return delivery
    }

    public func listDeliveries(
        userId: String?,
        userFirstName: String?,
        hospitalId: String?,
        musterId: String?,
        date: Date?,
        babyCount: Int?,
        deliveryMethod: DeliveryMethod?,
        epiduralUsed: Bool?
    ) async throws -> [Delivery] {
        return deliveries.filter { delivery in
            (userId == nil || delivery.userId == userId) &&
            (userFirstName == nil || delivery.userFirstName == userFirstName) &&
            (hospitalId == nil || delivery.hospitalId == hospitalId) &&
            (musterId == nil || delivery.musterId == musterId) &&
            (date == nil || Calendar.current.isDate(delivery.date, inSameDayAs: date!)) &&
            (babyCount == nil || delivery.babies.count == babyCount) &&
            (deliveryMethod == nil || delivery.deliveryMethod == deliveryMethod) &&
            (epiduralUsed == nil || delivery.epiduralUsed == epiduralUsed)
        }
    }

    public func createDelivery(_ delivery: Delivery) async throws -> Delivery {
        if deliveries.contains(where: { $0.id == delivery.id }) {
            throw DeliveryError.creationFailed("Delivery with ID \(delivery.id) already exists.")
        }
        deliveries.append(delivery)
        return delivery
    }

    public func updateDelivery(_ delivery: Delivery) async throws {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.notFound("Delivery with ID \(delivery.id) not found.")
        }
        deliveries[index] = delivery
    }

    public func deleteDelivery(_ delivery: Delivery) async throws {
        guard let index = deliveries.firstIndex(where: { $0.id == delivery.id }) else {
            throw DeliveryError.deletionFailed("Failed to delete delivery with ID \(delivery.id).")
        }
        deliveries.remove(at: index)
    }
}
