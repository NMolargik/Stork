//
//  LocationError.swift
//  StorkServices
//

import Foundation

public enum LocationError: LocalizedError {
    case notAuthorized
    case requestInProgress
    case updateFailed(underlying: Error)
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .notAuthorized: "Location access is not authorized."
        case .requestInProgress: "A location request is already in progress."
        case .updateFailed(let underlying): "Location update failed: \(underlying.localizedDescription)"
        case .unavailable: "Location services are unavailable."
        }
    }
}
