//
//  DeliveryError.swift
//
//
//  Created by Nick Molargik on 11/20/24.
//

import Foundation

/// An enumeration representing possible errors that can occur during delivery-related operations.
public enum DeliveryError: Error, LocalizedError {
    // MARK: - Cases

    /// Error thrown when a delivery record cannot be found.
    /// - Associated Value: A `String` providing details, such as the delivery ID.
    case notFound(String)

    /// Error thrown when invalid data is received.
    /// - Associated Value: A `String` describing the issue with the data.
    case invalidData(String)

    /// Error thrown when there is a general Firebase-related issue.
    /// - Associated Value: A `String` describing the Firebase error.
    case firebaseError(String)

    /// Error thrown when a delivery creation operation fails.
    /// - Associated Value: A `String` describing the reason for the failure.
    case creationFailed(String)

    /// Error thrown when a delivery update operation fails.
    /// - Associated Value: A `String` describing the reason for the failure.
    case updateFailed(String)

    /// Error thrown when a delivery deletion operation fails.
    /// - Associated Value: A `String` describing the reason for the failure.
    case deletionFailed(String)

    /// A generic error for unexpected issues.
    /// - Associated Value: A `String` describing the unknown error.
    case unknown(String)

    // MARK: - LocalizedError

    /// A localized message describing the error.
    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "The delivery with ID \(id) could not be found."
        case .invalidData(let details):
            return "The data received is invalid: \(details)"
        case .firebaseError(let message):
            return "A Firebase error occurred: \(message)"
        case .creationFailed(let message):
            return "Failed to create the delivery: \(message)"
        case .updateFailed(let message):
            return "Failed to update the delivery: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete the delivery: \(message)"
        case .unknown(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}
