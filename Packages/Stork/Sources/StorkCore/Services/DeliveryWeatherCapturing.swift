//
//  DeliveryWeatherCapturing.swift
//  StorkCore
//
//  Seam over "fetch the conditions outside right now" for the Pro weather-at-delivery
//  snapshot. The production conformance (`WeatherManager` in StorkServices) requests a
//  one-shot when-in-use location and asks WeatherKit; feature view models depend only on
//  this protocol so they test with a fake. Location is requested *only* through this path,
//  never at launch or in the background.
//

import Foundation

@MainActor
public protocol DeliveryWeatherCapturing: AnyObject {
    /// Captures the current conditions at the device's location.
    func captureCurrentWeather() async throws -> DeliveryWeather
}
