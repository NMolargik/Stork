//
//  SettingsModelTests.swift
//  StorkFeatureSettingsTests
//
//  Behavior tests for the settings view model: delete-all routing through its dedicated
//  use-case and error surfacing.
//

import Testing
import Foundation
import StorkCore
@testable import StorkFeatureSettings

@MainActor
private final class FakeStore {
    var deliveries: [Delivery] = []
    var errorToThrow: PersistenceError?
    private(set) var deleteAllCalls = 0

    struct Load: LoadDeliveries {
        let store: FakeStore
        func callAsFunction() throws(PersistenceError) -> [Delivery] {
            if let error = store.errorToThrow { throw error }
            return store.deliveries
        }
    }

    struct DeleteAll: DeleteAllDeliveries {
        let store: FakeStore
        func callAsFunction() throws(PersistenceError) {
            if let error = store.errorToThrow { throw error }
            store.deleteAllCalls += 1
            store.deliveries.removeAll()
        }
    }

    struct Log: LogDelivery {
        let store: FakeStore
        @discardableResult
        func callAsFunction(_ delivery: Delivery) throws(PersistenceError) -> MilestoneCelebration? {
            store.deliveries.append(delivery)
            return nil
        }
    }

    func makeModel() -> SettingsModel {
        SettingsModel(
            loadDeliveries: Load(store: self),
            deleteAllDeliveries: DeleteAll(store: self),
            logDelivery: Log(store: self)
        )
    }
}

@Suite("SettingsModel Tests")
@MainActor
struct SettingsModelTests {

    @Test("deleteAll routes through the use-case exactly once and reloads")
    func deleteAllRoutesOnce() {
        let store = FakeStore()
        store.deliveries = [
            Delivery(date: .now, babyCount: 1, deliveryMethod: .vaginal, epiduralUsed: false),
            Delivery(date: .now, babyCount: 2, deliveryMethod: .cSection, epiduralUsed: true),
        ]
        let model = store.makeModel()
        model.load()
        #expect(model.deliveryCount == 2)

        model.deleteAll()

        #expect(store.deleteAllCalls == 1)   // one transaction, not one call per delivery
        #expect(model.deliveryCount == 0)
        #expect(model.lastError == nil)
    }

    @Test("deleteAll failure surfaces through lastError")
    func deleteAllFailureSurfaces() {
        let store = FakeStore()
        let model = store.makeModel()
        store.errorToThrow = .saveFailed("disk full")

        model.deleteAll()

        #expect(model.lastError != nil)
    }

    @Test("appVersion reads a non-empty version string")
    func appVersion() {
        let model = FakeStore().makeModel()
        #expect(!model.appVersion.isEmpty)
    }
}
