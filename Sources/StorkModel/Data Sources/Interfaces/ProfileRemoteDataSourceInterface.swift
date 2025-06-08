//
//  ProfileRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation
import UIKit

/// A protocol defining the interface for remote data source interactions related to profiles.
public protocol ProfileRemoteDataSourceInterface {
    /// Creates a new profile record in Firestore and returns the newly created `Profile`.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Returns: The newly created `Profile`.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation operation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func createProfile(profile: Profile) async throws -> Profile

    /// Updates an existing profile record in Firestore and returns the updated `Profile`.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Returns: The updated `Profile`.
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update operation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func updateProfile(profile: Profile) async throws -> Profile
    
    /// Retrieves a single profile by its unique ID, throwing an error if not found.
    ///
    /// - Parameter id: The unique ID of the profile to fetch.
    /// - Returns: A `Profile` object representing the profile with the specified ID.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile cannot be found.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func getProfile(byId id: String) async throws -> Profile

    /// Retrieves the currently authenticated profile, throwing an error if not found or unavailable.
    ///
    /// - Returns: A `Profile` object representing the current authenticated user profile.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the current profile cannot be found.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
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
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
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

    /// Registers a new user account with an email and password, returning the newly registered `Profile`.
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object containing user information.
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the registered user.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the account creation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func registerWithEmail(profile: Profile, password: String) async throws -> Profile

    /// Signs in an existing user with an email and password, returning a `Profile` object representing the authenticated user.
    ///
    /// - Parameters:
    ///   - profile: A partial `Profile` object containing the user's email (e.g., `profile.email`).
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the authenticated user.
    /// - Throws:
    ///   - `ProfileError.authenticationFailed`: If the authentication fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func signInWithEmail(profile: Profile, password: String) async throws -> Profile
    
//    /// Re-authenticates the currently logged-in user with the given password.
//    /// - Parameters:
//    ///   - password: The password for the user's account.
//    /// - Throws:
//    ///   - `ProfileError.authenticationFailed` if re-auth fails.
//    func reauthenticateUser(password: String) async throws

    /// Signs out the currently authenticated user.
    ///
    /// - Throws:
    ///   - `ProfileError.signOutFailed`: If the sign-out operation fails.
    func signOut() async throws

    /// Sends a password reset email to the specified address.
    ///
    /// - Parameter email: The email address for which to send a password reset.
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func sendPasswordReset(email: String) async throws
    
    /// Deletes an existing profile record from Firestore.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion operation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func deleteProfile(profile: Profile) async throws
    
//    /// Terminates the user's account by re-authenticating with the provided password and then deleting the account.
//    ///
//    /// - Parameter password: The password used to re-authenticate before account termination.
//    /// - Throws:
//    ///   - `ProfileError.authenticationFailed`: If re-authentication fails.
//    ///   - `ProfileError.deletionFailed`: If the account deletion fails.
//    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
//    ///   - `ProfileError.unknown`: If any other error occurs.
//    func terminateUser(password: String) async throws
}
