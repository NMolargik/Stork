//
//  WeatherError.swift
//  StorkServices
//

import Foundation

public enum WeatherError: Error, LocalizedError {
    case locationProviderMissing
    case locationUnavailable
    case weatherServiceFailed

    public var errorDescription: String? {
        switch self {
        case .locationProviderMissing: "Location provider is missing."
        case .locationUnavailable: "Unable to determine current location."
        case .weatherServiceFailed: "Failed to fetch local weather."
        }
    }
}
