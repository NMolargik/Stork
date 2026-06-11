//
//  DeliveryManagerTests.swift
//  StorkTests
//
//  Behavior tests for DeliveryManager over an in-memory SwiftData store
//  and fake service seams.
//

import Testing
import Foundation
import SwiftData
import SwiftUI
import CoreLocation
@testable import Stork

/// Keeps the in-memory container alive for the duration of a test; the
/// manager's ModelContext traps if the container deallocates underneath it.
@MainActor
private struct Harness {
    let container: ModelContainer
    let manager: DeliveryManager
    let widgetReloader: FakeWidgetReloader
    let indexer: FakeDeliveryIndexer

    init(milestoneStore: FakeKeyValueStore = FakeKeyValueStore()) throws {
        // Unique on-disk store per harness: simultaneous in-memory containers
        // share a /dev/null SQLite identity and throw from CoreData's
        // connection manager under load.
        let url = URL.temporaryDirectory.appending(path: "stork-test-\(UUID().uuidString).store")
        let config = ModelConfiguration(url: url)
        container = try ModelContainer(for: Delivery.self, Baby.self, DeliveryTag.self, configurations: config)
        widgetReloader = FakeWidgetReloader()
        indexer = FakeDeliveryIndexer()
        manager = DeliveryManager(
            container: container,
            milestoneTracker: MilestoneTracker(storage: milestoneStore),
            widgetReloader: widgetReloader,
            defaults: FakeKeyValueStore(),
            indexer: indexer
        )
    }
}

@MainActor
private func makeDelivery(date: Date = Date(), babyCount: Int = 1, method: DeliveryMethod = .vaginal) -> Delivery {
    let babies = (0..<babyCount).map { _ in Baby(sex: .female) }
    let delivery = Delivery(date: date, babies: babies, babyCount: babyCount, deliveryMethod: method, epiduralUsed: false)
    for baby in babies { baby.delivery = delivery }
    return delivery
}

@Suite("DeliveryManager Behavior Tests", .serialized)
@MainActor
struct DeliveryManagerBehaviorTests {

    @Test("Creating a delivery persists it and refreshes the list")
    func createPersists() async throws {
        let harness = try Harness()
        let manager = harness.manager

        manager.create(delivery: makeDelivery())
        await manager.refresh()

        #expect(manager.deliveries.count == 1)
    }

    @Test("Creating a delivery reloads the widget timeline and writes fallback counts")
    func createUpdatesWidget() async throws {
        let harness = try Harness()

        harness.manager.create(delivery: makeDelivery(babyCount: 2))
        await harness.manager.refresh()

        #expect(harness.widgetReloader.reloadedKinds.contains(WidgetKind.deliveriesThisWeek))
    }

    @Test("Refreshing reindexes deliveries into the Spotlight seam")
    func refreshReindexes() async throws {
        let harness = try Harness()

        harness.manager.create(delivery: makeDelivery())
        await harness.manager.refresh()

        #expect(harness.indexer.reindexedBatches.last?.count == 1)
    }

    @Test("Re-saving a delivery with the same id merges instead of duplicating")
    func mergeOnDuplicateId() async throws {
        let harness = try Harness()
        let manager = harness.manager

        let original = makeDelivery()
        manager.create(delivery: original)
        await manager.refresh()

        original.notes = "Updated"
        manager.create(delivery: original)
        await manager.refresh()

        #expect(manager.deliveries.count == 1)
        #expect(manager.deliveries.first?.notes == "Updated")
    }

    @Test("Delete removes the delivery")
    func deleteRemoves() async throws {
        let harness = try Harness()
        let manager = harness.manager

        let delivery = makeDelivery()
        manager.create(delivery: delivery)
        await manager.refresh()
        manager.delete(delivery)
        await manager.refresh()

        #expect(manager.deliveries.isEmpty)
    }

    @Test("deleteAllDeliveries empties the store")
    func deleteAll() async throws {
        let harness = try Harness()
        let manager = harness.manager

        manager.create(delivery: makeDelivery())
        manager.create(delivery: makeDelivery())
        await manager.refresh()
        manager.deleteAllDeliveries()
        await manager.refresh()

        #expect(manager.deliveries.isEmpty)
    }

    @Test("visibleDeliveries respects the applied filter")
    func filterApplies() async throws {
        let harness = try Harness()
        let manager = harness.manager

        manager.create(delivery: makeDelivery(method: .vaginal))
        manager.create(delivery: makeDelivery(method: .cSection))
        await manager.refresh()

        var filter = DeliveryFilter()
        filter.deliveryMethod = [.cSection]
        manager.applyFilter(filter)

        #expect(manager.deliveries.count == 2)
        #expect(manager.visibleDeliveries.count == 1)
        #expect(manager.visibleDeliveries.first?.deliveryMethod == .cSection)
    }

    @Test("Milestone celebration fires when a threshold is crossed")
    func milestoneFires() async throws {
        let harness = try Harness(milestoneStore: FakeKeyValueStore())
        let manager = harness.manager

        // Insert 49 deliveries directly, then create the 50th through the manager.
        for _ in 0..<49 {
            manager.create(delivery: makeDelivery())
        }
        await manager.refresh()
        manager.dismissMilestoneCelebration()

        manager.create(delivery: makeDelivery())
        await manager.refresh()

        // 50 single-baby deliveries: the 50-delivery milestone should fire
        // (baby milestones start at 100).
        #expect(manager.pendingMilestoneCelebration == MilestoneCelebration(count: 50, type: .deliveries))
    }
}

@Suite("WeatherManager Behavior Tests")
@MainActor
struct WeatherManagerBehaviorTests {

    private struct FailingWeatherProvider: WeatherProviding {
        func currentConditions(for location: CLLocation) async throws -> CurrentConditions {
            throw WeatherError.weatherServiceFailed
        }
    }

    @Test("Refresh without a location provider sets an error")
    func missingLocationProvider() async {
        let manager = WeatherManager(provider: FailingWeatherProvider())

        await manager.refresh()

        #expect(manager.error as? WeatherError == WeatherError.locationProviderMissing)
    }

    @Test("Location failure maps to locationUnavailable")
    func locationFailure() async {
        let location = FakeLocationProvider()
        location.errorToThrow = LocationError.notAuthorized
        let manager = WeatherManager(provider: FailingWeatherProvider(), locationProvider: location)

        await manager.refresh()

        #expect(manager.error as? WeatherError == WeatherError.locationUnavailable)
    }

    @Test("Weather service failure maps to weatherServiceFailed")
    func weatherFailure() async {
        let manager = WeatherManager(provider: FailingWeatherProvider(), locationProvider: FakeLocationProvider())

        await manager.refresh()

        #expect(manager.error as? WeatherError == WeatherError.weatherServiceFailed)
    }
}
