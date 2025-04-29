//
//  MockProfileRepository.swift
//
//
//  Created by Nick Molargik on 11/20/24.
//

import SkipFoundation
import SwiftUI

/// A mock implementation of the `ProfileRepositoryInterface` protocol for testing purposes.
public class MockProfileRepository: ProfileRepositoryInterface {
    // MARK: - Properties

    /// A list of mock profiles used for in-memory storage.
    private var profiles: [Profile]

    // MARK: - Initializer

    /// Initializes the mock repository with optional sample data.
    ///
    /// - Parameter profiles: An array of `Profile` objects to initialize the repository with.
    ///   Defaults to an empty array.
    public init(profiles: [Profile] = []) {
        self.profiles = profiles
    }

    // MARK: - Create

    /// Creates a new profile and returns the newly created `Profile`.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Returns: The newly created `Profile`.
    /// - Throws:
    ///   - `ProfileError.creationFailed` if a profile with the same ID already exists.
    public func createProfile(profile: Profile) async throws -> Profile {
        if profiles.contains(where: { $0.id == profile.id }) {
            throw ProfileError.creationFailed("Profile with ID \(profile.id) already exists.")
        }
        profiles.append(profile)
        return profile
    }

    // MARK: - Update

    /// Updates an existing profile and returns the updated `Profile`.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Returns: The updated `Profile`.
    /// - Throws:
    ///   - `ProfileError.notFound` if the profile does not exist.
    public func updateProfile(profile: Profile) async throws -> Profile {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            throw ProfileError.notFound("Profile with ID \(profile.id) not found.")
        }
        profiles[index] = profile
        return profile
    }

    // MARK: - Fetch

    /// Fetches a single profile by its unique ID.
    ///
    /// - Parameter id: The unique ID of the profile to fetch.
    /// - Returns: A `Profile` object representing the fetched profile.
    /// - Throws:
    ///   - `ProfileError.notFound` if no profile with the specified ID exists.
    public func getProfile(byId id: String) async throws -> Profile {
        guard let profile = profiles.first(where: { $0.id == id }) else {
            throw ProfileError.notFound("Profile with ID \(id) not found.")
        }
        return profile
    }
    
    /// Retrieves the currently “authenticated” profile (mocked as the first one in the list).
    ///
    /// - Returns: A `Profile` object representing the current “logged-in” profile.
    /// - Throws: `ProfileError.notFound` if there is no profile available.
    public func getCurrentProfile() async throws -> Profile {
        guard let profile = profiles.first else {
            throw ProfileError.notFound("No profile is currently logged in.")
        }
        return profile
    }

    // MARK: - Listing

    /// Lists profiles based on optional filter criteria. (In this mock, simply returns all.)
    ///
    /// - Parameters:
    ///   - id: An optional filter for the profile ID.
    ///   - firstName: An optional filter for the profile's first name.
    ///   - lastName: An optional filter for the profile's last name.
    ///   - email: An optional filter for the profile's email address.
    ///   - birthday: An optional filter for the profile's birthday.
    ///   - role: An optional filter for the profile's role.
    ///   - primaryHospital: An optional filter for the profile's primary hospital ID.
    ///   - joinDate: An optional filter for the profile's join date.
    ///   - musterId: An optional filter for the muster ID associated with the profile.
    /// - Returns: An array of `Profile` objects matching the specified filters (currently unchanged for the mock).
    public func listProfiles(
        id: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        birthday: Date? = nil,
        role: ProfileRole? = nil,
        primaryHospital: String? = nil,
        joinDate: Date? = nil,
        musterId: String? = nil
    ) async throws -> [Profile] {
        // In a real implementation, you'd filter based on parameters.
        // For the mock, we simply return the entire list.
        return profiles
    }
    
    // MARK: - Auth Checks
    
    /// Determines if there is a currently authenticated user (mock always returns `true` if there's at least one profile).
    ///
    /// - Returns: `true` if at least one profile exists, otherwise `false`.
    public func isAuthenticated() -> Bool {
        return !profiles.isEmpty
    }

    // MARK: - Registration

    /// Registers a new user account with an email and password, returning the newly registered `Profile`.
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object containing user data.
    ///   - password: The password for the new user account (not used in this mock).
    /// - Returns: The newly registered `Profile`.
    /// - Throws: `ProfileError.creationFailed` if a profile with the same ID already exists.
    public func registerWithEmail(profile: Profile, password: String) async throws -> Profile {
        if profiles.contains(where: { $0.id == profile.id }) {
            throw ProfileError.creationFailed("Profile with ID \(profile.id) already exists.")
        }
        profiles.append(profile)
        return profile
    }
    
    // MARK: - Sign In

    /// Signs in an existing user with an email and password, returning the authenticated `Profile`.
    ///
    /// - Parameters:
    ///   - profile: A `Profile` containing at least the user's email.
    ///   - password: The password for the user's account (not used in this mock).
    /// - Returns: A `Profile` object representing the authenticated user.
    /// - Throws: `ProfileError.authenticationFailed` if a matching profile cannot be found or verified.
    public func signInWithEmail(profile: Profile, password: String) async throws -> Profile {
        // If this is a real sign-in, you'd check credentials. Here, we simply add the profile if not present.
        if let existingProfile = profiles.first(where: { $0.email == profile.email }) {
            return existingProfile
        } else {
            // For the mock, treat "not found" as authentication fail, or add and return.
            // We'll just add the profile to simulate a "successful sign in".
            profiles.append(profile)
            return profile
        }
    }
    
    // MARK: - Sign Out

    /// Signs out the currently authenticated user (mock simply clears the list).
    public func signOut() async throws {
        profiles.removeAll()
    }
    
    // MARK: - Password Reset

    /// Sends a password reset email to the specified address (mocked as a no-op).
    ///
    /// - Parameter email: The email address for which to send a password reset link.
    public func sendPasswordReset(email: String) async throws {
        // No-op for this mock
    }
    
    // MARK: - Delete

    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.deletionFailed` if the profile does not exist in storage.
    public func deleteProfile(profile: Profile) async throws {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            throw ProfileError.deletionFailed("Failed to delete profile with ID \(profile.id).")
        }
        profiles.remove(at: index)
    }
    
    // MARK: - Terminate

    /// Terminates the currently authenticated user's account, re-authenticating if necessary.
    /// For the mock, we simply clear the list.
    ///
    /// - Parameter password: The password used for re-auth (not used in this mock).
//    public func terminateUser(password: String) async throws {
//        profiles.removeAll()
//    }
}
