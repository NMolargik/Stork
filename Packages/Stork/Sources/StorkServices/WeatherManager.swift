//
//  WeatherManager.swift
//  StorkServices
//
//  Fetches and caches current conditions, throttled to one successful WeatherKit request
//  per hour to limit cost. WeatherKit is reached through `WeatherProviding` and location
//  through `LocationProviding`, so both are testable with fakes.
//

import Foundation
import CoreLocation
import WeatherKit
import Observation
import os
import StorkCore

@MainActor
@Observable
public final class WeatherManager {

    @ObservationIgnored private let provider: any WeatherProviding
    public private(set) var locationProvider: (any LocationProviding)?

    public private(set) var isFetching = false
    public private(set) var lastUpdated: Date?
    public var error: Error?

    public private(set) var temperature: Measurement<UnitTemperature>?
    public private(set) var condition: WeatherCondition?

    /// Only successful requests advance this cooldown.
    public var refreshCooldownInterval: TimeInterval = 60 * 60

    public init(provider: any WeatherProviding = WeatherKitProvider(), locationProvider: (any LocationProviding)? = nil) {
        self.provider = provider
        self.locationProvider = locationProvider
    }

    public func setLocationProvider(_ provider: (any LocationProviding)?) {
        locationProvider = provider
    }

    // MARK: - Refresh

    /// One-off refresh using the current provider's location.
    public func refresh() async {
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
    public func fetch(for location: CLLocation) async throws {
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

    /// Temperature formatted for the user's chosen unit system (overrides locale).
    public func temperatureString(useMetric: Bool) -> String? {
        guard let temperature else { return nil }
        let converted = temperature.converted(to: useMetric ? .celsius : .fahrenheit)
        return Self.temperatureFormatter.string(from: converted)
    }

    /// Temperature formatted for the device locale.
    public var temperatureString: String? {
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
