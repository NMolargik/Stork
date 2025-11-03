//
//  LocationError.swift
//  Stork
//
//  Created by Nick Molargik on 9/16/25.
//

import Foundation

enum LocationError: LocalizedError {
    case notAuthorized
    case requestInProgress
    case updateFailed(underlying: Error)
    case unavailable
}
