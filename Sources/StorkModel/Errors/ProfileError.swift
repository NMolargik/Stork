//
//  ProfileError.swift
//
//
//  Created by Nick Molargik on 11/20/24.
//

import Foundation

/// Enum representing possible errors related to profile operations.
public enum ProfileError: Error, CustomStringConvertible, LocalizedError {
    /// The profile was not found.
    case notFound(String)

    /// The data for the profile was invalid or could not be parsed.
    case invalidData(String)

    /// The creation of a new profile failed.
    case creationFailed(String)

    /// The update of an existing profile failed.
    case updateFailed(String)

    /// The deletion of a profile failed.
    case deletionFailed(String)

    /// A Firebase-related error occurred.
    case firebaseError(String)
    
    /// A profile picture upload failed
    case uploadError(String)
    
    /// No email was matched
    case missingEmail(String)
    
    /// No password was provided
    case missingPassword(String)
    
    /// Invalid login credentials were used
    case invalidCredentials(String)

    /// An unknown error occurred.
    case unknown(String)

    // MARK: - Description

    /// Provides a user-friendly description of the error.
    public var description: String {
        switch self {
        case .notFound(let message):
            return "Profile not found: \(message)"
        case .invalidData(let message):
            return "Invalid profile data: \(message)"
        case .creationFailed(let message):
            return "Failed to create profile: \(message)"
        case .updateFailed(let message):
            return "Failed to update profile: \(message)"
        case .deletionFailed(let message):
            return "Failed to delete profile: \(message)"
        case .firebaseError(let message):
            return "Firebase error: \(message)"
        case .uploadError(let message):
            return "Firebase upload error: \(message)"
        case .missingEmail(let message):
            return "Firebase login error: \(message)"
        case .missingPassword(let message):
            return "Firebase login error: \(message)"
        case .invalidCredentials(let message):
            return "Firebase login error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
