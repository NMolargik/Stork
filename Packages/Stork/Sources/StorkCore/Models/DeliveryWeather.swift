//
//  DeliveryWeather.swift
//  StorkCore
//
//  The weather snapshot a Pro user can attach when logging a delivery. Stored flat on
//  `Delivery` (three optional columns, CloudKit-friendly) and surfaced as this value type.
//  Temperature is stored in Celsius; display converts to the user's unit preference.
//

import Foundation

nonisolated public struct DeliveryWeather: Equatable, Sendable, Codable {
    /// Air temperature in degrees Celsius.
    public let temperatureCelsius: Double
    /// WeatherKit `WeatherCondition` raw value (e.g. "clear", "rain"); kept as a string so Core stays framework-free.
    public let conditionName: String
    /// SF Symbol that depicts the condition (e.g. "sun.max.fill").
    public let symbolName: String

    public init(temperatureCelsius: Double, conditionName: String, symbolName: String) {
        self.temperatureCelsius = temperatureCelsius
        self.conditionName = conditionName
        self.symbolName = symbolName
    }

    /// Temperature formatted in the user's preferred unit, whole degrees ("72°F", "22°C").
    public func temperatureString(useMetric: Bool) -> String {
        let measurement = Measurement(value: temperatureCelsius, unit: UnitTemperature.celsius)
        let converted = measurement.converted(to: useMetric ? .celsius : .fahrenheit)
        return converted.formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    /// Human-readable condition derived from the WeatherKit raw value ("partlyCloudy" → "Partly Cloudy").
    public var conditionDisplayName: String {
        var result = ""
        for (index, character) in conditionName.enumerated() {
            if character.isUppercase && index > 0 { result.append(" ") }
            result.append(index == 0 ? Character(character.uppercased()) : character)
        }
        return result
    }
}
