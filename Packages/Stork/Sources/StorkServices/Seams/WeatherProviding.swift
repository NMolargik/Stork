//
//  WeatherProviding.swift
//  StorkServices
//
//  Seam over WeatherKit so weather-dependent logic (cooldowns, error mapping) can be
//  tested without network calls.
//

import CoreLocation
import WeatherKit

/// The current conditions Stork displays.
public struct CurrentConditions: Sendable {
    public let temperature: Measurement<UnitTemperature>
    public let condition: WeatherCondition

    public init(temperature: Measurement<UnitTemperature>, condition: WeatherCondition) {
        self.temperature = temperature
        self.condition = condition
    }
}

public protocol WeatherProviding: Sendable {
    func currentConditions(for location: CLLocation) async throws -> CurrentConditions
}

public struct WeatherKitProvider: WeatherProviding {
    public init() {}

    public func currentConditions(for location: CLLocation) async throws -> CurrentConditions {
        let current = try await WeatherService.shared.weather(for: location, including: .current)
        return CurrentConditions(temperature: current.temperature, condition: current.condition)
    }
}
