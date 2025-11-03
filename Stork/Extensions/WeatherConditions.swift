//
//  WeatherConditions.swift
//  Stork
//
//  Created by Nick Molargik on 11/2/25.
//

import SwiftUI
import WeatherKit

extension WeatherCondition {
    /// SF Symbol name to represent this condition in Mygra
    var weatherSymbolName: String {
        switch self {
        case .clear, .mostlyClear: return "sun.max.fill"
        case .partlyCloudy:        return "cloud.sun.fill"
        case .cloudy, .mostlyCloudy:return "cloud.fill"
        case .drizzle, .rain:       return "cloud.rain.fill"
        case .heavyRain:            return "cloud.heavyrain.fill"
        case .strongStorms:         return "cloud.bolt.rain.fill"
        case .snow, .flurries:      return "cloud.snow.fill"
        case .sleet, .freezingRain: return "cloud.sleet.fill"
        case .haze, .foggy:         return "cloud.fog.fill"
        case .windy:                return "wind"
        case .blowingSnow, .blizzard:return "wind.snow"
        case .frigid:               return "thermometer.snowflake"
        case .hot:                  return "thermometer.sun.fill"
        case .smoky:                return "smoke.fill"
        default:                    return "cloud.fill"
        }
    }

    /// Palette colors to layer onto the SF Symbol, ordered by layer
    var weatherSymbolColors: (layer1: Color, layer2: Color) {
        switch self {
        case .clear, .mostlyClear:             return (.yellow, .yellow)      // single-layer look
        case .partlyCloudy:                    return (.gray, .yellow)        // cloud + sun
        case .cloudy, .mostlyCloudy:           return (.gray, .gray)
        case .drizzle, .rain:                  return (.gray, .blue)
        case .heavyRain:                       return (.gray, Color.blue.opacity(0.9))
        case .strongStorms:                    return (.gray, .indigo)
        case .snow, .flurries:                 return (.gray, .cyan)
        case .sleet, .freezingRain:            return (.gray, .teal)
        case .haze, .foggy:                    return (.gray, .gray.opacity(0.6))
        case .windy:                           return (.teal, .teal)
        case .blowingSnow, .blizzard:          return (.gray, .cyan)
        case .frigid:                          return (.blue, .blue)
        case .hot:                             return (.red, .orange)
        case .smoky:                           return (.brown, .brown)
        default:                               return (.gray, .gray.opacity(0.7))
        }
    }

    /// Human-friendly label for the condition
    var weatherSymbolLabel: String {
        switch self {
        case .clear: return "Clear"
        case .mostlyClear: return "Mostly Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .mostlyCloudy: return "Mostly Cloudy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rain"
        case .heavyRain: return "Heavy Rain"
        case .strongStorms: return "Thunderstorms"
        case .snow: return "Snow"
        case .flurries: return "Flurries"
        case .sleet: return "Sleet"
        case .freezingRain: return "Freezing Rain"
        case .haze: return "Haze"
        case .foggy: return "Fog"
        case .windy: return "Windy"
        case .blowingSnow: return "Blowing Snow"
        case .frigid: return "Frigid"
        case .hot: return "Hot"
        case .blizzard: return "Blizzard"
        case .smoky: return "Smoky"
        default: return "Weather"
        }
    }

    /// Ready-to-use symbol view with palette colors. Apply font/effects at call site.
    @ViewBuilder
    func weatherSymbolView() -> some View {
        let colors = weatherSymbolColors
        Image(systemName: weatherSymbolName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(colors.layer1.gradient, colors.layer2.gradient)
    }
}
