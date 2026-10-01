//
//  DeliveryRepositoryTests.swift
//  StorkDataTests
//
//  Behavior tests for DefaultDeliveryRepository over an in-memory SwiftData store and
//  fake side-effect seams.
//

import Testing
import Foundation
import SwiftData
import StorkCore
@testable import StorkData

/// Keeps the on-disk store alive for the test; the repository's context traps if the
/// container deallocates underneath it.
@MainActor
private struct Harness {
    let container: ModelContainer
    let repository: DefaultDeliveryRepository
    let widgetReloader: FakeWidgetReloader
    let indexer: FakeDeliveryIndexer
    let reviewRequester: FakeReviewRequester
    let changeCenter = DeliveryChangeCenter()

    init(milestoneStore: FakeKeyValueStore = FakeKeyValueStore()) throws {
        // Unique on-disk store per harness: simultaneous in-memory containers share a
        // /dev/null SQLite identity and throw under load.
        let url = URL.temporaryDirectory.appending(path: "stork-test-\(UUID().uuidString).store")
        let config = ModelConfiguration(url: url)
        container = try ModelContainer(for: Delivery.self, Baby.self, DeliveryTag.self, configurations: config)
        widgetReloader = FakeWidgetReloader()
        indexer = FakeDeliveryIndexer()
        reviewRequester = FakeReviewRequester()
        repository = DefaultDeliveryRepository(
            container: container,
            defaults: FakeKeyValueStore(),
            widgetReloader: widgetReloader,
            milestoneTracker: MilestoneTracker(storage: milestoneStore),
            indexer: indexer,
            reviewRequester: reviewRequester,
            changeCenter: changeCenter
        )
    }
}

@MainActor
private func makeDelivery(date: Date = .now, babyCount: Int = 1, method: DeliveryMethod = .vaginal) -> Delivery {
    let babies = (0..<babyCount).map { _ in Baby(sex: .female) }
    let delivery = Delivery(date: date, babies: babies, babyCount: babyCount, deliveryMethod: method, epiduralUsed: false)
    for baby in babies { baby.delivery = delivery }
    return delivery
}

@Suite("DeliveryRepository Behavior Tests", .serialized)
@MainActor
struct DeliveryRepositoryTests {

    @Test("Adding a delivery persists it")
    func addPersists() throws {
        let harness = try Harness()
        try harness.repository.add(makeDelivery())
        #expect(try harness.repository.deliveries().count == 1)
    }

    @Test("Adding reloads the widget timeline")
    func addReloadsWidget() throws {
        let harness = try Harness()
        try harness.repository.add(makeDelivery(babyCount: 2))
        #expect(harness.widgetReloader.reloadedKinds.contains(WidgetKind.deliveriesThisWeek))
    }

    @Test("Adding reindexes deliveries into the Spotlight seam")
    func addReindexes() throws {
        let harness = try Harness()
        try harness.repository.add(makeDelivery())
        #expect(harness.indexer.reindexedBatches.last?.count == 1)
    }

    @Test("Delete removes the delivery")
    func deleteRemoves() throws {
        let harness = try Harness()
        let delivery = makeDelivery()
        try harness.repository.add(delivery)
        try harness.repository.delete(delivery)
        #expect(try harness.repository.deliveries().isEmpty)
    }

    @Test("Career totals count deliveries and babies")
    func careerTotals() throws {
        let harness = try Harness()
        try harness.repository.add(makeDelivery(babyCount: 2))
        try harness.repository.add(makeDelivery(babyCount: 1))
        #expect(harness.repository.careerTotals() == CareerTotals(deliveries: 2, babies: 3))
    }

    @Test("deleteAll empties the store with a single side-effect pass")
    func deleteAllSingleSideEffectPass() throws {
        let harness = try Harness()
        try harness.repository.add(makeDelivery())
        try harness.repository.add(makeDelivery())
        let reloadsAfterAdds = harness.widgetReloader.reloadedKinds.count

        try harness.repository.deleteAll()

        #expect(try harness.repository.deliveries().isEmpty)
        #expect(harness.repository.careerTotals() == CareerTotals(deliveries: 0, babies: 0))
        // Exactly one more widget reload — not one per deleted delivery.
        #expect(harness.widgetReloader.reloadedKinds.count == reloadsAfterAdds + 1)
    }

    @Test("The fifth delivery triggers a review request exactly once")
    func reviewOnFifth() throws {
        let harness = try Harness()
        for _ in 0..<5 { try harness.repository.add(makeDelivery()) }
        #expect(harness.reviewRequester.requestCount == 1)
        try harness.repository.add(makeDelivery())
        #expect(harness.reviewRequester.requestCount == 1)
    }

    @Test("Crossing the 50-delivery milestone is returned from add")
    func milestoneFires() throws {
        let harness = try Harness()
        for _ in 0..<49 { try harness.repository.add(makeDelivery()) }
        let milestone = try harness.repository.add(makeDelivery())
        #expect(milestone == MilestoneCelebration(count: 50, type: .deliveries))
    }

    @Test("Every successful mutation notifies the delivery change stream")
    func mutationsNotifyStream() async throws {
        let harness = try Harness()
        var iterator = harness.changeCenter.changes().makeAsyncIterator()

        let delivery = makeDelivery()
        try harness.repository.add(delivery)       // yield 1
        try harness.repository.delete(delivery)    // yield 2

        #expect(await iterator.next() != nil)
        #expect(await iterator.next() != nil)
    }
}
