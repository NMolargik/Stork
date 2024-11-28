//
//  DefaultProfileRepository.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI

/// A repository implementation for managing profile-related operations.
public class DefaultProfileRepository: ProfileRepositoryInterface {
    // MARK: - Properties
    
    /// The remote data source for profile operations.
    private let remoteDataSource: ProfileRemoteDataSourceInterface

    // MARK: - Initializer

    /// Initializes the repository with a remote data source.
    ///
    /// - Parameter remoteDataSource: An instance of `ProfileRemoteDataSourceInterface`.
    public init(remoteDataSource: ProfileRemoteDataSourceInterface) {
        self.remoteDataSource = remoteDataSource
    }

    // MARK: - Methods

    /// Fetches a single profile by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the profile to fetch.
    /// - Returns: A `Profile` object representing the fetched profile.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile cannot be found.
    ///   - `ProfileError`: For other failures during the fetch operation.
    public func getProfile(byId id: String) async throws -> Profile {
        return try await remoteDataSource.getProfile(byId: id)
    }
    
    public func getCurrentProfile() async throws -> Profile {
        return try await remoteDataSource.getCurrentProfile()
    }

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
    public func listProfiles(
        id: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        birthday: Date? = nil,
        role: ProfileRole? = nil,
        primaryHospital: String? = nil,
        joinDate: Date? = nil,
        musterId: String? = nil,
        isAdmin: Bool? = nil
    ) async throws -> [Profile] {
        return try await remoteDataSource.listProfiles(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            birthday: birthday,
            role: role,
            primaryHospital: primaryHospital,
            joinDate: joinDate,
            musterId: musterId,
            isAdmin: isAdmin
        )
    }

    /// Creates a new profile.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation fails.
    ///   - `ProfileError`: For other failures during the creation operation.
    public func createProfile(_ profile: Profile) async throws {
        try await remoteDataSource.createProfile(profile)
    }

    /// Updates an existing profile.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other failures during the update operation.
    public func updateProfile(_ profile: Profile) async throws {
        try await remoteDataSource.updateProfile(profile)
    }

    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Parameter password: The password for the profile, for confirmation purposes
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other failures during the deletion operation.
    public func deleteProfile(_ profile: Profile, password: String) async throws {
        try await remoteDataSource.deleteProfile(profile, password: password)
    }
    
    public func registerWithEmail(_ profile: Profile, password: String) async throws -> Profile {
        try await remoteDataSource.registerWithEmail(profile, password: password)
        
    }
    
    public func signInWithEmail(_ profile: Profile, password: String) async throws -> Profile {
        try await remoteDataSource.signInWithEmail(profile, password: password)
    }
    
    public func signOut() async {
        await remoteDataSource.signOut()
    }

    /// Uploads a profile picture for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.uploadFailed`: If the upload process fails.
    ///   - `ProfileError`: For other failures during the upload operation.
    public func uploadProfilePicture(_ profile: Profile) async throws {
        return try await remoteDataSource.uploadProfilePicture(profile)
    }

    /// Retrieves the profile picture for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Returns: A `Data` object containing the image data of the profile picture.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile picture does not exist.
    ///   - `ProfileError`: For other failures during the retrieval operation.
    public func retrieveProfilePicture(_ profile: Profile) async throws -> UIImage? {
        return try await remoteDataSource.retrieveProfilePicture(profile)
    }
    
    public func isAuthenticated() -> Bool {
        return remoteDataSource.isAuthenticated()
    }
    
    public func sendPasswordReset(email: String) async throws {
        return try await remoteDataSource.sendPasswordReset(email: email)
    }
}
