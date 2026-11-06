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
    /// SF Symbol for the condition (WeatherKit's own when available).
    public let symbolName: String

    public init(temperature: Measurement<UnitTemperature>, condition: WeatherCondition, symbolName: String? = nil) {
        self.temperature = temperature
        self.condition = condition
        self.symbolName = symbolName ?? condition.weatherSymbolName
    }
}

public protocol WeatherProviding: Sendable {
    func currentConditions(for location: CLLocation) async throws -> CurrentConditions
}

public struct WeatherKitProvider: WeatherProviding {
    public init() {}

    public func currentConditions(for location: CLLocation) async throws -> CurrentConditions {
        let current = try await WeatherService.shared.weather(for: location, including: .current)
        return CurrentConditions(temperature: current.temperature, condition: current.condition, symbolName: current.symbolName)
    }
}
