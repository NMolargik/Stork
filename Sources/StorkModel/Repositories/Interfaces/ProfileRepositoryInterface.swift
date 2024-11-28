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
    /// Fetches a single profile by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the profile to fetch.
    /// - Returns: A `Profile` object representing the fetched profile.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile cannot be found.
    ///   - `ProfileError`: If another error occurs during the fetch operation.
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
        musterId: String?,
        isAdmin: Bool?
    ) async throws -> [Profile]

    /// Creates a new profile.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation fails.
    ///   - `ProfileError`: For other errors during the creation operation.
    func createProfile(_ profile: Profile) async throws

    /// Updates an existing profile.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other errors during the update operation.
    func updateProfile(_ profile: Profile) async throws

    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Parameter password: The password for the profile, for confirmation purposes
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other errors during the deletion operation.
    func deleteProfile(_ profile: Profile, password: String) async throws
    
    func registerWithEmail(_ profile: Profile, password: String) async throws -> Profile
    
    func signInWithEmail(_ profile: Profile, password: String) async throws -> Profile
    
    func signOut() async

    /// Uploads a profile picture to Firebase Storage.
    ///
    /// - Parameter profile: The `Profile` object to delete
    /// - Throws:
    ///   - `ProfileError.uploadFailed`: If the upload process fails.
    ///   - `ProfileError`: For other errors during the upload operation.
    func uploadProfilePicture(_ profile: Profile) async throws

    /// Retrieves a profile picture from Firebase Storage.
    ///
    /// - Parameter profile: The `Profile` object to reference
    /// - Returns: A `UIImage` representing the profile picture
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile picture does not exist.
    ///   - `ProfileError`: For other errors during the retrieval operation.
    func retrieveProfilePicture(_ profile: Profile) async throws -> UIImage?
    
    func isAuthenticated() -> Bool
    
    func sendPasswordReset(email: String) async throws
}
