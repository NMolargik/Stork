//
//  MusterError.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// An enumeration representing possible errors that can occur during Muster operations.
public enum MusterError: Error, LocalizedError {
    // MARK: - Cases

    /// Error thrown when a muster cannot be found.
    case notFound(String)

    /// Error thrown when there is an issue with the API.
    case apiError(String)

    /// Error thrown when there is an issue with Firebase.
    case firebaseError(String)

    /// Error thrown when a muster creation operation fails.
    case creationFailed(String)

    /// Error thrown when a muster update operation fails.
    case updateFailed(String)

    /// Error thrown when a muster deletion operation fails.
    case deletionFailed(String)

    /// Error thrown when data for a muster is invalid or cannot be parsed.
    case invalidData(String)

    /// A generic error for unexpected issues.
    case unknown(String)

    // MARK: - LocalizedError

    /// A localized message describing the error.
    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Muster with ID \(id) not found."
        case .apiError(let message):
            return "API error: \(message)"
        case .firebaseError(let message):
            return "Firebase error: \(message)"
        case .creationFailed(let message):
            return "Failed to create muster: \(message)"
        case .updateFailed(let message):
            return "Failed to update muster: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete muster: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}
