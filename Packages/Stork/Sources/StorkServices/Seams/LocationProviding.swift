//
//  LocationProviding.swift
//  StorkServices
//
//  What consumers (e.g. weather refresh) need from a location source, abstracted so they
//  can be tested with a fake provider.
//

import CoreLocation

@MainActor
public protocol LocationProviding: AnyObject {
    var isAuthorized: Bool { get }
    func requestAuthorization()
    func currentLocation() async throws -> CLLocation
}
