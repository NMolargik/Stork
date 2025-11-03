//
//  WeatherManager.swift
//  Stork
//
//  Created by Nick Molargik on 10/2/25.
//

import Foundation
import CoreLocation
import WeatherKit
import Observation

@MainActor
@Observable
final class WeatherManager {

    // MARK: - Dependencies
    private let service: WeatherService
    // Optional location manager provided by onboarding or elsewhere.
    private(set) var locationManager: LocationManager?

    // MARK: - State
    private(set) var isFetching = false
    private(set) var lastUpdated: Date?
    var error: Error?

    private(set) var temperature: Measurement<UnitTemperature>?
    private(set) var condition: WeatherCondition?

    /// Global cooldown to avoid costly WeatherKit hits from any trigger.
    /// Only successful requests advance this cooldown. If a successful request was made less than this interval ago, we skip new requests.
    /// Set to 1 hour to limit updates and reduce WeatherKit costs.
    var refreshCooldownInterval: TimeInterval = 60 * 60 // 1 hour

    // MARK: - Cached formatters
    private static let tempFormatter: MeasurementFormatter = {
        let fmt = MeasurementFormatter()
        fmt.unitOptions = .naturalScale
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        nf.minimumFractionDigits = 0
        fmt.numberFormatter = nf
        return fmt
    }()

    // MARK: - Init
    init(service: WeatherService = .shared, locationManager: LocationManager? = nil) {
        self.service = service
        self.locationManager = locationManager
    }

    // MARK: - Wiring
    func setLocationProvider(_ manager: LocationManager?) {
        self.locationManager = manager
    }

    // MARK: - Refresh

    /// One-off refresh using the current provider’s current location.
    func refresh() async {
        // Cooldown gate for manual refresh
        if let last = lastUpdated, Date().timeIntervalSince(last) < refreshCooldownInterval {
            return
        }

        guard let provider = locationManager else {
            print("No location provider for WeatherManager")
            error = WeatherError.locationProviderMissing
            return
        }
        do {
            let loc: CLLocation
            do {
                loc = try await provider.currentLocation()
            } catch {
                self.error = WeatherError.locationUnavailable
                return
            }
            try await fetch(for: loc)
        } catch {
            if error is WeatherError {
                self.error = error
            } else {
                self.error = WeatherError.weatherServiceFailed
            }
        }
    }

    /// Core fetch for a specific location.
    func fetch(for location: CLLocation) async throws {
        // Cooldown gate (applies to any caller)
        if let last = lastUpdated, Date().timeIntervalSince(last) < refreshCooldownInterval {
            return
        }

        isFetching = true
        error = nil
        defer { isFetching = false }

        let current = try await service.weather(for: location, including: .current)

        self.temperature = current.temperature
        self.condition   = current.condition
        self.lastUpdated = Date()
    }

    // MARK: - UI conveniences

    var temperatureString: String? {
        guard let t = temperature else { return nil }
        return Self.tempFormatter.string(from: t)
    }
}
