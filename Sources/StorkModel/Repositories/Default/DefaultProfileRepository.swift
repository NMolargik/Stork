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
    
    /// Creates a new profile.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation fails.
    ///   - `ProfileError`: For other failures during the creation operation.
    public func createProfile(profile: Profile) async throws {
        do {
            try await remoteDataSource.createProfile(profile: profile)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.creationFailed("Failed to create profile: \(error.localizedDescription)")
        }
    }

    /// Updates an existing profile.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other failures during the update operation.
    public func updateProfile(profile: Profile) async throws {
        do {
            try await remoteDataSource.updateProfile(profile: profile)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
    }

    /// Fetches a single profile by its unique ID.
    ///
    /// - Parameter id: The unique identifier of the profile to fetch.
    /// - Returns: A `Profile` object representing the fetched profile.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile cannot be found.
    ///   - `ProfileError`: For other failures during the fetch operation.
    public func getProfile(byId id: String) async throws -> Profile {
        do {
            return try await remoteDataSource.getProfile(byId: id)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.notFound("Failed to find profile: \(error.localizedDescription)")
        }
    }
    
    public func getCurrentProfile() async throws -> Profile {
        do {
            return try await remoteDataSource.getCurrentProfile()
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.notFound("Failed to collect current profile: \(error.localizedDescription)")
        }
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
        do {
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
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.fetchFailed("Failed to fetch profiles: \(error.localizedDescription)")
        }
    }
    
    public func registerWithEmail(profile: Profile, password: String) async throws {
        do {
            try await remoteDataSource.registerWithEmail(profile: profile, password: password)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.creationFailed("Failed to register profiles: \(error.localizedDescription)")
        }
    }
    
    public func signInWithEmail(profile: Profile, password: String) async throws {
        do {
            try await remoteDataSource.signInWithEmail(profile: profile, password: password)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.authenticationFailed("Failed to authenticate profile: \(error.localizedDescription)")
        }
    }
    
    public func signOut() async throws {
        do {
            try await remoteDataSource.signOut()
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.fetchFailed("Failed to fetch profiles: \(error.localizedDescription)")
        }
    }

    /// Uploads a profile picture for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.uploadFailed`: If the upload process fails.
    ///   - `ProfileError`: For other failures during the upload operation.
    public func uploadProfilePicture(profile: Profile, profilePicture: UIImage) async throws {
        do {
            try await remoteDataSource.uploadProfilePicture(profile: profile, profilePicture: profilePicture)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.pictureUploadFailed("Failed to upload picture: \(error.localizedDescription)")
        }
    }

    /// Retrieves the profile picture for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Returns: A `Data` object containing the image data of the profile picture.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the profile picture does not exist.
    ///   - `ProfileError`: For other failures during the retrieval operation.
    public func retrieveProfilePicture(profile: Profile) async throws -> UIImage? {
        do {
            return try await remoteDataSource.retrieveProfilePicture(profile: profile)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.pictureRetrievalFailed("Failed to retrieve picture: \(error.localizedDescription)")
        }
    }
    
    public func sendPasswordReset(email: String) async throws {
        do {
            return try await remoteDataSource.sendPasswordReset(email: email)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.passwordResetFailed("Failed to reset password: \(error.localizedDescription)")
        }
    }
    
    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Parameter password: The password for the profile, for confirmation purposes
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other failures during the deletion operation.
    public func deleteProfile(profile: Profile, password: String) async throws {
        do {
            try await remoteDataSource.deleteProfile(profile: profile, password: password)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.deletionFailed("Failed to delete profile: \(error.localizedDescription)")
        }
    }
}
