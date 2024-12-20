//
//  ProfileRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import UIKit

/// A protocol defining the interface for remote data source interactions related to profiles.
public protocol ProfileRemoteDataSourceInterface {
    /// Creates a new profile record in Firestore.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation operation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func createProfile(profile: Profile) async throws

    /// Updates an existing profile record in Firestore.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update operation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func updateProfile(profile: Profile) async throws
    
    /// Retrieves a single profile by its unique ID.
    ///
    /// - Parameter id: The unique ID of the profile to fetch.
    /// - Returns: A `Profile` object representing the profile with the specified ID.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile cannot be found.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func getProfile(byId id: String) async throws -> Profile

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
    ///   - isAdmin: An optional filter for whether the profile has admin privileges.
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
        musterId: String?,
        isAdmin: Bool?
    ) async throws -> [Profile]

    /// Registers a new user account with an email and password.
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object containing user information.
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the registered user.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the account creation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func registerWithEmail(profile: Profile, password: String) async throws -> String

    /// Signs in an existing user with an email and password.
    ///
    /// - Parameters:
    ///   - profile: A partial `Profile` object containing the user's email.
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the authenticated user.
    /// - Throws:
    ///   - `ProfileError.authenticationFailed`: If the authentication fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func signInWithEmail(profile: Profile, password: String) async throws

    /// Signs out the currently authenticated user.
    ///
    /// - Throws:
    ///   - `ProfileError.signOutFailed`: If the sign-out operation fails.
    func signOut() async throws

    /// Uploads a profile picture to Firebase Storage.
    ///
    /// - Parameter profile: The `Profile` object to associate
    /// - Parameter profilePicture: A `UIImage` of the picture to upload
    /// - Throws:
    ///   - `ProfileError.uploadFailed`: If the upload operation fails.
    ///   - `ProfileError.firebaseError`: If the Firebase Storage operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func uploadProfilePicture(profile: Profile, profilePicture: UIImage) async throws

    /// Retrieves a profile picture from Firebase Storage.
    ///
    /// - Parameter profile: The `Profile` object containing the reference to the image.
    /// - Returns: A `UIImage` object representing the profile picture.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the image cannot be found.
    ///   - `ProfileError.firebaseError`: If the Firebase Storage operation fails.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func retrieveProfilePicture(profile: Profile) async throws -> UIImage?
    
    func sendPasswordReset(email: String) async throws
    
    /// Deletes an existing profile record from Firestore.
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object to delete.
    ///   - password: The user's password for confirmation.
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion operation fails.
    ///   - `ProfileError.firebaseError`: If the Firestore operation fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError.unknown`: If any other error occurs.
    func deleteProfile(profile: Profile, password: String) async throws
}
