//
//  LocationProviding.swift
//  Stork
//

import CoreLocation

/// What consumers (e.g. weather refresh) need from a location source,
/// abstracted so they can be tested with a fake provider.
@MainActor
protocol LocationProviding: AnyObject {
    var isAuthorized: Bool { get }
    func requestAuthorization()
    func currentLocation() async throws -> CLLocation
}
