//
//  HospitalError.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// An enumeration representing possible errors that can occur during hospital-related operations.
public enum HospitalError: Error, LocalizedError {
    // MARK: - Cases

    /// Error thrown when a hospital cannot be found.
    case notFound(String)

    /// Error thrown when there is an issue with Firestore.
    case firebaseError(String)

    /// Error thrown when a hospital creation operation fails.
    case creationFailed(String)

    /// Error thrown when a hospital update operation fails.
    case updateFailed(String)

    /// Error thrown when a hospital deletion operation fails.
    case deletionFailed(String)

    /// Error thrown when input validation fails.
    case validationFailed(String)
    
    /// Search criteria incorrect
    case invalidData(String)

    /// Error thrown when no hospitals are found for a specific query.
    case noResults(String)

    /// Error thrown when mapping Firestore data to a `Hospital` object fails.
    case mappingError(String)
    
    /// User has not allowed location access
    case locationAccessDenied(String)
    
    /// Issue collecting user location
    case locationUnknown(String)

    /// Generic error for unexpected issues.
    case unknown(String)

    // MARK: - LocalizedError

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return "Hospital not found: \(message)"
        case .firebaseError(let message):
            return "Firestore error: \(message)"
        case .creationFailed(let message):
            return "Hospital creation failed: \(message)"
        case .updateFailed(let message):
            return "Hospital update failed: \(message)"
        case .deletionFailed(let message):
            return "Hospital deletion failed: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .invalidData(let message):
            return "This search is not valid: \(message)"
        case .noResults(let message):
            return "No results found: \(message)"
        case .mappingError(let message):
            return "Data mapping error: \(message)"
        case .locationAccessDenied(let message):
            return "Location Access Error: \(message)"
        case .locationUnknown(let message):
            return "Location Unknown Error: \(message)"
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}
