//
//  WeatherManager.swift
//  Stork
//

import Foundation
import CoreLocation
import WeatherKit
import Observation
import os

/// Fetches and caches current conditions, throttled to one successful
/// WeatherKit request per hour to limit cost.
@MainActor
@Observable
final class WeatherManager {

    @ObservationIgnored private let provider: WeatherProviding
    private(set) var locationProvider: LocationProviding?

    private(set) var isFetching = false
    private(set) var lastUpdated: Date?
    var error: Error?

    private(set) var temperature: Measurement<UnitTemperature>?
    private(set) var condition: WeatherCondition?

    /// Only successful requests advance this cooldown.
    var refreshCooldownInterval: TimeInterval = 60 * 60

    init(provider: WeatherProviding = WeatherKitProvider(), locationProvider: LocationProviding? = nil) {
        self.provider = provider
        self.locationProvider = locationProvider
    }

    func setLocationProvider(_ provider: LocationProviding?) {
        locationProvider = provider
    }

    // MARK: - Refresh

    /// One-off refresh using the current provider's location.
    func refresh() async {
        guard !isInCooldown else { return }

        guard let locationProvider else {
            Log.weather.error("No location provider configured.")
            error = WeatherError.locationProviderMissing
            return
        }

        let location: CLLocation
        do {
            location = try await locationProvider.currentLocation()
        } catch {
            self.error = WeatherError.locationUnavailable
            return
        }

        do {
            try await fetch(for: location)
        } catch {
            self.error = (error as? WeatherError) ?? WeatherError.weatherServiceFailed
        }
    }

    /// Core fetch for a specific location. Subject to the cooldown.
    func fetch(for location: CLLocation) async throws {
        guard !isInCooldown else { return }

        isFetching = true
        error = nil
        defer { isFetching = false }

        let current = try await provider.currentConditions(for: location)

        temperature = current.temperature
        condition = current.condition
        lastUpdated = Date()
    }

    private var isInCooldown: Bool {
        guard let lastUpdated else { return false }
        return Date().timeIntervalSince(lastUpdated) < refreshCooldownInterval
    }

    // MARK: - Display

    /// Temperature formatted for the user's chosen unit system.
    /// `useMetric` overrides locale so the in-app unit toggle is respected.
    func temperatureString(useMetric: Bool) -> String? {
        guard let temperature else { return nil }
        let converted = temperature.converted(to: useMetric ? .celsius : .fahrenheit)
        return Self.temperatureFormatter.string(from: converted)
    }

    /// Temperature formatted for the device locale.
    var temperatureString: String? {
        guard let temperature else { return nil }
        return Self.localeTemperatureFormatter.string(from: temperature)
    }

    private static let temperatureFormatter: MeasurementFormatter = {
        let fmt = MeasurementFormatter()
        fmt.unitOptions = .providedUnit
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        fmt.numberFormatter = nf
        return fmt
    }()

    private static let localeTemperatureFormatter: MeasurementFormatter = {
        let fmt = MeasurementFormatter()
        fmt.unitOptions = .naturalScale
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 0
        fmt.numberFormatter = nf
        return fmt
    }()
}
