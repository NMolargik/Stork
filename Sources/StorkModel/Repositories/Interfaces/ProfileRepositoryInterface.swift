//
//  ProfileRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI

/// A protocol defining the repository interface for managing Profile entities.
///
/// This protocol acts as an abstraction layer between the domain and data layers,
/// allowing the application to interact with profile-related data sources consistently.
public protocol ProfileRepositoryInterface {
    
    // MARK: - Create & Update

    /// Creates a new profile and returns the newly created `Profile`.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Returns: The newly created `Profile`, including its assigned ID if generated on the server.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation fails.
    ///   - `ProfileError`: For other errors during the creation operation.
    func createProfile(profile: Profile) async throws -> Profile

    /// Updates an existing profile and returns the updated `Profile`.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Returns: The updated `Profile` (potentially reflecting server-side changes).
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other errors during the update operation.
    func updateProfile(profile: Profile) async throws -> Profile
    
    // MARK: - Fetching Profiles
    
    /// Fetches a single profile by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the profile to fetch.
    /// - Returns: A `Profile` object representing the fetched profile.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile cannot be found.
    ///   - `ProfileError`: If another error occurs during the fetch operation.
    func getProfile(byId id: String) async throws -> Profile
    
    /// Fetches the currently authenticated profile from the connected data source.
    ///
    /// - Returns: A `Profile` object representing the current authenticated user.
    /// - Throws:
    ///   - `ProfileError.notFound`: If no valid authenticated user or profile is found.
    ///   - `ProfileError`: For other errors during the fetch operation.
    func getCurrentProfile() async throws -> Profile
    
    /// Lists profiles based on optional filter criteria.
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
    /// - Returns: An array of `Profile` objects matching the specified filters.
    /// - Throws: `ProfileError` if the operation fails.
    func listProfiles(
        id: String?,
        firstName: String?,
        lastName: String?,
        email: String?,
        birthday: Date?,
        role: ProfileRole?,
        primaryHospital: String?,
        joinDate: Date?,
        musterId: String?
    ) async throws -> [Profile]

    // MARK: - Deleting Profiles
    
    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other errors during the deletion operation.
    func deleteProfile(profile: Profile) async throws
    
    // MARK: - Auth Operations

    /// Registers a new user account with an email and password, returning the newly registered user's ID.
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object containing the user's initial data.
    ///   - password: The password for the new user account.
    /// - Returns: An updated `Profile` object
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If registration fails.
    ///   - `ProfileError`: For other errors during the registration process.
    func registerWithEmail(profile: Profile, password: String) async throws -> Profile

    /// Signs in an existing user with an email and password, returning the authenticated `Profile`.
    ///
    /// - Parameters:
    ///   - profile: A partial `Profile` object containing the user's email (e.g., `profile.email`).
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the authenticated user.
    /// - Throws:
    ///   - `ProfileError.authenticationFailed`: If the credentials are invalid or sign-in fails.
    ///   - `ProfileError`: For other errors during the sign-in process.
    func signInWithEmail(profile: Profile, password: String) async throws -> Profile

    /// Signs out the currently authenticated user.
    ///
    /// - Throws: `ProfileError.signOutFailed` if the sign-out operation fails.
    func signOut() async throws

    /// Sends a password reset email to the specified address.
    ///
    /// - Parameter email: The email address for which to send a password reset link.
    /// - Throws: `ProfileError.firebaseError` or `ProfileError.unknown` as appropriate if the reset fails.
    func sendPasswordReset(email: String) async throws
    
    /// Terminates the currently authenticated user's account.
    ///
    /// This typically requires re-authentication if the user hasn't recently logged in,
    /// then deletes both the Auth user and the user's profile record in Firestore.
    ///
    /// - Parameter password: The password used to re-authenticate before account termination.
    /// - Throws:
    ///   - `ProfileError.authenticationFailed`: If re-authentication fails.
    ///   - `ProfileError.deletionFailed`: If the account deletion fails.
    ///   - `ProfileError.notFound`: If no current user can be located.
    ///   - `ProfileError`: For other errors during the termination process.
//    func terminateUser(password: String) async throws
}
