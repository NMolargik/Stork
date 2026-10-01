//
//  Fakes.swift
//  StorkDataTests
//
//  Fakes for the side-effect seams, so repository behavior is verified without touching
//  WidgetKit, CoreSpotlight, or real defaults.
//

import Foundation
import StorkCore

/// In-memory `KeyValueStoring` fake.
final class FakeKeyValueStore: KeyValueStoring {
    private(set) var storage: [String: Any] = [:]
    func bool(forKey defaultName: String) -> Bool { storage[defaultName] as? Bool ?? false }
    func integer(forKey defaultName: String) -> Int { storage[defaultName] as? Int ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func data(forKey defaultName: String) -> Data? { storage[defaultName] as? Data }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
    func set(_ value: Bool, forKey defaultName: String) { storage[defaultName] = value }
    func set(_ value: Int, forKey defaultName: String) { storage[defaultName] = value }
}

/// Records widget reload requests.
@MainActor
final class FakeWidgetReloader: WidgetTimelineReloading {
    private(set) var reloadedKinds: [String] = []
    private(set) var reloadedAll = false
    func reloadTimelines(ofKind kind: String) { reloadedKinds.append(kind) }
    func reloadAllTimelines() { reloadedAll = true }
}

/// Records Spotlight reindex requests.
@MainActor
final class FakeDeliveryIndexer: DeliveryIndexing {
    private(set) var reindexedBatches: [[Delivery]] = []
    func reindex(_ deliveries: [Delivery]) { reindexedBatches.append(deliveries) }
}

/// Records review-prompt requests.
@MainActor
final class FakeReviewRequester: ReviewRequesting {
    private(set) var requestCount = 0
    func requestReview() { requestCount += 1 }
}
