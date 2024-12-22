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
    /// Creates a new profile.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation fails.
    ///   - `ProfileError`: For other errors during the creation operation.
    func createProfile(profile: Profile) async throws

    /// Updates an existing profile.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other errors during the update operation.
    func updateProfile(profile: Profile) async throws
    
    /// Fetches a single profile by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the profile to fetch.
    /// - Returns: A `Profile` object representing the fetched profile.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile cannot be found.
    ///   - `ProfileError`: If another error occurs during the fetch operation.
    func getProfile(byId id: String) async throws -> Profile
    
    
    /// Fetches the profile currently assigned to the connected data source
    /// - Throws:
    /// TODO: document, make throw
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

    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Parameter password: The password for the profile, for confirmation purposes
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other errors during the deletion operation.
    func deleteProfile(profile: Profile, password: String) async throws
    
    
    func registerWithEmail(profile: Profile, password: String) async throws -> String
    
    func signInWithEmail(profile: Profile, password: String) async throws
    
    func signOut() async throws

    func sendPasswordReset(email: String) async throws
}
