//
//  TestDoubles.swift
//  StorkTests
//
//  Fakes for the protocol seams, so manager behavior can be verified
//  without touching real system frameworks.
//

import Foundation
import CoreLocation
@testable import Stork

/// In-memory `KeyValueStoring` fake.
final class FakeKeyValueStore: KeyValueStoring {
    private(set) var storage: [String: Any] = [:]

    func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    func stringArray(forKey defaultName: String) -> [String]? {
        storage[defaultName] as? [String]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func set(_ value: Bool, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func set(_ value: Int, forKey defaultName: String) {
        storage[defaultName] = value
    }
}

/// Records widget reload requests.
final class FakeWidgetReloader: WidgetTimelineReloading {
    private(set) var reloadedKinds: [String] = []

    func reloadTimelines(ofKind kind: String) {
        reloadedKinds.append(kind)
    }
}

/// Records Spotlight reindex requests.
@MainActor
final class FakeDeliveryIndexer: DeliveryIndexing {
    private(set) var reindexedBatches: [[Delivery]] = []

    func reindex(_ deliveries: [Delivery]) {
        reindexedBatches.append(deliveries)
    }
}

/// Stubbed location provider.
@MainActor
final class FakeLocationProvider: LocationProviding {
    var isAuthorized: Bool = true
    var locationToReturn: CLLocation = CLLocation(latitude: 41.0793, longitude: -85.1394)
    var errorToThrow: Error?
    private(set) var requestCount = 0

    func requestAuthorization() {}

    func currentLocation() async throws -> CLLocation {
        requestCount += 1
        if let errorToThrow { throw errorToThrow }
        return locationToReturn
    }
}
