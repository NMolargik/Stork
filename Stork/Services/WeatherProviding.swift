//
//  WeatherProviding.swift
//  Stork
//

import CoreLocation
import WeatherKit

/// The current conditions Stork displays.
struct CurrentConditions {
    let temperature: Measurement<UnitTemperature>
    let condition: WeatherCondition
}

/// Seam over WeatherKit so weather-dependent logic (cooldowns, error
/// mapping) can be tested without network calls.
protocol WeatherProviding: Sendable {
    func currentConditions(for location: CLLocation) async throws -> CurrentConditions
}

struct WeatherKitProvider: WeatherProviding {
    func currentConditions(for location: CLLocation) async throws -> CurrentConditions {
        let current = try await WeatherService.shared.weather(for: location, including: .current)
        return CurrentConditions(temperature: current.temperature, condition: current.condition)
    }
}
