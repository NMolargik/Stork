//
//  LocationManager.swift
//  StorkServices
//
//  CoreLocation wrapper conforming to `LocationProviding`: a one-shot `currentLocation()`
//  with observable authorization state. Deliberately *only* when-in-use, one-shot
//  (`requestLocation`), never continuous updates or Always authorization — location exists
//  solely to attach a weather snapshot while the user is logging a delivery.
//

import Foundation
import CoreLocation
import Observation
import os

@MainActor
@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate, LocationProviding {

    public private(set) var isAuthorized: Bool = false
    public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public private(set) var lastLocation: CLLocation?

    private let manager = CLLocationManager()
    private var oneShotContinuation: CheckedContinuation<CLLocation, Error>?

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
        updateAuth(from: manager.authorizationStatus)
    }

    // MARK: - Authorization

    public func requestAuthorization() {
        let status = manager.authorizationStatus
        updateAuth(from: status)
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    // MARK: - One-shot location

    public func currentLocation() async throws -> CLLocation {
        if isAuthorized, let loc = manager.location {
            lastLocation = loc
            return loc
        }

        requestAuthorization()

        guard isAuthorized else { throw LocationError.notAuthorized }
        if oneShotContinuation != nil { throw LocationError.requestInProgress }
        guard CLLocationManager.locationServicesEnabled() else { throw LocationError.unavailable }

        manager.requestLocation()
        return try await withCheckedThrowingContinuation { cont in
            self.oneShotContinuation = cont
        }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuth(from: manager.authorizationStatus)
        if oneShotContinuation != nil, !isAuthorized {
            oneShotContinuation?.resume(throwing: LocationError.notAuthorized)
            oneShotContinuation = nil
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        lastLocation = last
        if let cont = oneShotContinuation {
            oneShotContinuation = nil
            cont.resume(returning: last)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let cont = oneShotContinuation {
            oneShotContinuation = nil
            cont.resume(throwing: LocationError.updateFailed(underlying: error))
        }
    }

    // MARK: - Helpers

    private func updateAuth(from status: CLAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }
}
