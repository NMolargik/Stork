//
//  WeatherError.swift
//  Stork
//
//  Created by Nick Molargik on 10/2/25.
//

import Foundation

enum WeatherError: Error, LocalizedError {
    case locationProviderMissing
    case locationUnavailable
    case weatherServiceFailed

    var message: String? {
        switch self {
        case .locationProviderMissing:
            return "Location provider is missing."
        case .locationUnavailable:
            return "Unable to determine current location."
        case .weatherServiceFailed:
            return "Failed to fetch local weather."
        }
    }
}
