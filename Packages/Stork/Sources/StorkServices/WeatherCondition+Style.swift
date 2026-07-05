//
//  WeatherCondition+Style.swift
//  StorkServices
//
//  SF Symbol, palette, and label for each WeatherKit condition, plus a ready-to-use
//  symbol view. Lives with the weather manager since it is WeatherKit-coupled.
//

import SwiftUI
import WeatherKit

public extension WeatherCondition {
    /// SF Symbol name representing this condition.
    var weatherSymbolName: String {
        switch self {
        case .clear, .mostlyClear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy, .mostlyCloudy: "cloud.fill"
        case .drizzle, .rain: "cloud.rain.fill"
        case .heavyRain: "cloud.heavyrain.fill"
        case .strongStorms: "cloud.bolt.rain.fill"
        case .snow, .flurries: "cloud.snow.fill"
        case .sleet, .freezingRain: "cloud.sleet.fill"
        case .haze, .foggy: "cloud.fog.fill"
        case .windy: "wind"
        case .blowingSnow, .blizzard: "wind.snow"
        case .frigid: "thermometer.snowflake"
        case .hot: "thermometer.sun.fill"
        case .smoky: "smoke.fill"
        default: "cloud.fill"
        }
    }

    /// Palette colors to layer onto the SF Symbol, ordered by layer.
    var weatherSymbolColors: (layer1: Color, layer2: Color) {
        switch self {
        case .clear, .mostlyClear: (.yellow, .yellow)
        case .partlyCloudy: (.gray, .yellow)
        case .cloudy, .mostlyCloudy: (.gray, .gray)
        case .drizzle, .rain: (.gray, .blue)
        case .heavyRain: (.gray, Color.blue.opacity(0.9))
        case .strongStorms: (.gray, .indigo)
        case .snow, .flurries: (.gray, .cyan)
        case .sleet, .freezingRain: (.gray, .teal)
        case .haze, .foggy: (.gray, .gray.opacity(0.6))
        case .windy: (.teal, .teal)
        case .blowingSnow, .blizzard: (.gray, .cyan)
        case .frigid: (.blue, .blue)
        case .hot: (.red, .orange)
        case .smoky: (.brown, .brown)
        default: (.gray, .gray.opacity(0.7))
        }
    }

    /// Human-friendly label for the condition.
    var weatherSymbolLabel: String {
        switch self {
        case .clear: "Clear"
        case .mostlyClear: "Mostly Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .mostlyCloudy: "Mostly Cloudy"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .heavyRain: "Heavy Rain"
        case .strongStorms: "Thunderstorms"
        case .snow: "Snow"
        case .flurries: "Flurries"
        case .sleet: "Sleet"
        case .freezingRain: "Freezing Rain"
        case .haze: "Haze"
        case .foggy: "Fog"
        case .windy: "Windy"
        case .blowingSnow: "Blowing Snow"
        case .frigid: "Frigid"
        case .hot: "Hot"
        case .blizzard: "Blizzard"
        case .smoky: "Smoky"
        default: "Weather"
        }
    }

    /// Ready-to-use palette symbol view. Apply font/effects at the call site.
    @ContentBuilder
    func weatherSymbolView() -> some View {
        let colors = weatherSymbolColors
        Image(systemName: weatherSymbolName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(colors.layer1.gradient, colors.layer2.gradient)
    }
}
