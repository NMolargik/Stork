//
//  LocationManager.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation
import CoreLocation
import Observation
import os

@MainActor
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: - Public observable state
    private(set) var isAuthorized: Bool = false
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var lastLocation: CLLocation?

    // MARK: - Private
    private let manager = CLLocationManager()

    // For the AsyncStream of updates
    private var streamContinuation: AsyncStream<CLLocation>.Continuation?

    // For one-shot currentLocation() awaiting a single delegate result
    private var oneShotContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: - Init
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100 // meters

        // Seed initial status (use instance property; class method is deprecated)
        updateAuth(from: manager.authorizationStatus)
    }

    // MARK: - Authorization

    func requestAuthorization() {
        // If already authorized sufficiently, reflect and return.
        let status = manager.authorizationStatus
        updateAuth(from: status)

        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Caller may choose to direct user to Settings.
            break
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }

    // MARK: - One-shot location

    func currentLocation() async throws -> CLLocation {
        // If the manager already has a cached location and we’re authorized, use it.
        if isAuthorized, let loc = manager.location {
            lastLocation = loc
            return loc
        }

        // Ensure we’ve requested authorization
        requestAuthorization()

        // If not authorized, throw a standard error
        guard isAuthorized else {
            throw LocationError.notAuthorized
        }

        // Prevent multiple simultaneous requests
        if oneShotContinuation != nil {
            throw LocationError.requestInProgress
        }

        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.unavailable
        }

        manager.requestLocation()

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocation, Error>) in
            self.oneShotContinuation = cont
        }
    }

    // MARK: - Continuous updates

    func locationUpdates() -> AsyncStream<CLLocation> {
        requestAuthorization()

        // Start updates immediately; will be stopped when stream terminates
        manager.startUpdatingLocation()

        return AsyncStream { continuation in
            self.streamContinuation = continuation

            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.manager.stopUpdatingLocation()
                    self.streamContinuation = nil
                }
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuth(from: manager.authorizationStatus)
        // Optionally, if a caller is awaiting a one-shot and user denies mid-flow, fail it.
        if oneShotContinuation != nil, !isAuthorized {
            oneShotContinuation?.resume(throwing: LocationError.notAuthorized)
            oneShotContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        lastLocation = last

        // Fulfill one-shot if pending
        if let cont = oneShotContinuation {
            oneShotContinuation = nil
            cont.resume(returning: last)
        }

        // Yield to stream if active
        streamContinuation?.yield(last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // If one-shot is waiting, fail it
        if let cont = oneShotContinuation {
            oneShotContinuation = nil
            cont.resume(throwing: LocationError.updateFailed(underlying: error))
        }

        // For stream: choose policy. Here we don’t finish the stream on transient errors.
        // Callers can decide how to handle lack of updates.
    }

    // MARK: - Helpers

    private func map(error: Error) -> LocationError {
        // If it's already a LocationError, pass it through
        if let locErr = error as? LocationError { return locErr }
        // Prefer underlying CLError codes when possible
        let ns = error as NSError
        if ns.domain == kCLErrorDomain {
            // Map some common CLError codes
            switch CLError.Code(rawValue: ns.code) {
            case .denied?:
                return .notAuthorized
            case .locationUnknown?:
                return .updateFailed(underlying: error)
            default:
                return .updateFailed(underlying: error)
            }
        }
        return .updateFailed(underlying: error)
    }

    private func updateAuth(from status: CLAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
        case .notDetermined, .restricted, .denied:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
}
