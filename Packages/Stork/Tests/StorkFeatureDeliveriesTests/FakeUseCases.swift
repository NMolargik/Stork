//
//  FakeUseCases.swift
//  StorkFeatureDeliveriesTests
//
//  In-memory conformances to the Core use-case protocols. This is the payoff of the
//  use-case seams: view models are exercised with zero SwiftData containers, zero
//  simulators — just protocol substitution.
//

import Foundation
import StorkCore
import StorkFeatureDeliveries

/// Shared mutable backing store the fake use-cases read and write.
@MainActor
final class FakeDeliveryData {
    var deliveries: [Delivery] = []
    var tags: [DeliveryTag] = []

    /// When set, every throwing use-case throws this instead of acting.
    var errorToThrow: PersistenceError?

    /// Milestone returned by the next `LogDelivery` call.
    var milestoneToReturn: MilestoneCelebration?

    // Call records, so tests assert on interactions rather than side effects.
    private(set) var loggedDeliveries: [Delivery] = []
    private(set) var updatedDeliveries: [Delivery] = []
    private(set) var deletedDeliveries: [Delivery] = []
    private(set) var savedTags: [DeliveryTag] = []

    // MARK: - Use-case conformances

    struct Load: LoadDeliveries {
        let data: FakeDeliveryData
        func callAsFunction() throws(PersistenceError) -> [Delivery] {
            if let error = data.errorToThrow { throw error }
            return data.deliveries
        }
    }

    struct LogNew: LogDelivery {
        let data: FakeDeliveryData
        @discardableResult
        func callAsFunction(_ delivery: Delivery) throws(PersistenceError) -> MilestoneCelebration? {
            if let error = data.errorToThrow { throw error }
            data.deliveries.insert(delivery, at: 0)
            data.loggedDeliveries.append(delivery)
            return data.milestoneToReturn
        }
    }

    struct Update: UpdateDelivery {
        let data: FakeDeliveryData
        func callAsFunction(_ delivery: Delivery) throws(PersistenceError) {
            if let error = data.errorToThrow { throw error }
            data.updatedDeliveries.append(delivery)
        }
    }

    struct Delete: DeleteDelivery {
        let data: FakeDeliveryData
        func callAsFunction(_ delivery: Delivery) throws(PersistenceError) {
            if let error = data.errorToThrow { throw error }
            data.deliveries.removeAll { $0.id == delivery.id }
            data.deletedDeliveries.append(delivery)
        }
    }

    struct LoadAllTags: LoadTags {
        let data: FakeDeliveryData
        func callAsFunction() throws(PersistenceError) -> [DeliveryTag] {
            if let error = data.errorToThrow { throw error }
            return data.tags
        }
    }

    struct Save: SaveTag {
        let data: FakeDeliveryData
        func callAsFunction(_ tag: DeliveryTag, isNew: Bool) throws(PersistenceError) {
            if let error = data.errorToThrow { throw error }
            if isNew { data.tags.append(tag) }
            data.savedTags.append(tag)
        }
    }
}

/// Convenience builders so each test reads as intent, not wiring.
@MainActor
enum Make {
    static func listModel(data: FakeDeliveryData) -> DeliveryListModel {
        DeliveryListModel(
            loadDeliveries: FakeDeliveryData.Load(data: data),
            deleteDelivery: FakeDeliveryData.Delete(data: data),
            loadTags: FakeDeliveryData.LoadAllTags(data: data)
        )
    }

    static func entryModel(data: FakeDeliveryData, existing: Delivery? = nil) -> DeliveryEntryModel {
        DeliveryEntryModel(
            existingDelivery: existing,
            logDelivery: FakeDeliveryData.LogNew(data: data),
            updateDelivery: FakeDeliveryData.Update(data: data),
            loadTags: FakeDeliveryData.LoadAllTags(data: data),
            saveTag: FakeDeliveryData.Save(data: data)
        )
    }

    static func delivery(
        date: Date = .now,
        babyCount: Int = 1,
        method: DeliveryMethod = .vaginal,
        notes: String? = nil
    ) -> Delivery {
        let babies = (0..<babyCount).map { _ in Baby(sex: .female) }
        let delivery = Delivery(
            date: date,
            babies: babies,
            babyCount: babyCount,
            deliveryMethod: method,
            epiduralUsed: false,
            notes: notes
        )
        for baby in babies { baby.delivery = delivery }
        return delivery
    }
}
