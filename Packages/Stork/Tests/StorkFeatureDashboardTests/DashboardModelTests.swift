//
//  DashboardModelTests.swift
//  StorkFeatureDashboardTests
//
//  Behavior tests for the dashboard view model: card-order persistence through the
//  KeyValueStoring seam and jar-count delegation to DeliveryStatistics.
//

import Testing
import Foundation
import StorkCore
@testable import StorkFeatureDashboard

/// In-memory `KeyValueStoring` fake.
private final class FakeKeyValueStore: KeyValueStoring {
    var storage: [String: Any] = [:]
    func bool(forKey defaultName: String) -> Bool { storage[defaultName] as? Bool ?? false }
    func integer(forKey defaultName: String) -> Int { storage[defaultName] as? Int ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func data(forKey defaultName: String) -> Data? { storage[defaultName] as? Data }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
    func set(_ value: Bool, forKey defaultName: String) { storage[defaultName] = value }
    func set(_ value: Int, forKey defaultName: String) { storage[defaultName] = value }
}

private struct FakeLoadDeliveries: LoadDeliveries {
    var deliveries: [Delivery] = []
    func callAsFunction() throws(PersistenceError) -> [Delivery] { deliveries }
}

@Suite("DashboardModel Tests")
@MainActor
struct DashboardModelTests {

    @Test("Card order defaults to the declaration order on first launch")
    func defaultCardOrder() {
        let model = DashboardModel(loadDeliveries: FakeLoadDeliveries(), store: FakeKeyValueStore())
        #expect(model.cardOrder == DashboardCard.defaultOrder)
    }

    @Test("saveOrder persists through the seam and survives a fresh model")
    func orderPersists() {
        let store = FakeKeyValueStore()
        let model = DashboardModel(loadDeliveries: FakeLoadDeliveries(), store: store)

        let reversed = Array(DashboardCard.defaultOrder.reversed())
        model.saveOrder(reversed)
        #expect(model.cardOrder == reversed)

        // A brand-new model over the same store sees the saved order.
        let rebuilt = DashboardModel(loadDeliveries: FakeLoadDeliveries(), store: store)
        #expect(rebuilt.cardOrder == reversed)
    }

    @Test("A saved order missing newly added cards backfills them at the end")
    func orderBackfillsNewCards() {
        let store = FakeKeyValueStore()
        // Persist an order that omits the last card (simulating an older app version).
        let partial = Array(DashboardCard.defaultOrder.dropLast())
        DashboardCard.saveOrder(partial, to: store)

        let loaded = DashboardCard.loadOrder(from: store)
        #expect(Set(loaded) == Set(DashboardCard.allCases))
        #expect(loaded.last == DashboardCard.defaultOrder.last)
    }

    @Test("Jar counts reflect only the current month's babies by sex")
    func jarCounts() {
        let boy = Baby(sex: .male)
        let girl = Baby(sex: .female)
        let thisMonth = Delivery(date: .now, babies: [boy, girl], babyCount: 2, deliveryMethod: .vaginal, epiduralUsed: false)
        boy.delivery = thisMonth
        girl.delivery = thisMonth

        let old = Baby(sex: .male)
        let lastYear = Delivery(
            date: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
            babies: [old], babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false
        )
        old.delivery = lastYear

        let model = DashboardModel(
            loadDeliveries: FakeLoadDeliveries(deliveries: [thisMonth, lastYear]),
            store: FakeKeyValueStore()
        )
        model.load()

        let counts = model.monthlyJarCounts
        #expect(counts.boy == 1)
        #expect(counts.girl == 1)
        #expect(counts.loss == 0)
    }
}
