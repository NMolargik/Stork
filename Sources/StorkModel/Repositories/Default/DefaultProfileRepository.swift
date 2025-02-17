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

    // MARK: - Create

    /// Creates a new profile and returns the newly created `Profile`.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Returns: The newly created `Profile`, potentially including a generated `id` if provided by the server.
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If the creation fails.
    ///   - `ProfileError`: For other failures during the creation operation.
    public func createProfile(profile: Profile) async throws -> Profile {
        do {
            let newProfile = try await remoteDataSource.createProfile(profile: profile)
            return newProfile
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.creationFailed("Failed to create profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    /// Updates an existing profile and returns the updated `Profile`.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Returns: The updated `Profile`, reflecting any server-side changes.
    /// - Throws:
    ///   - `ProfileError.updateFailed`: If the update fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other failures during the update operation.
    public func updateProfile(profile: Profile) async throws -> Profile {
        do {
            let updatedProfile = try await remoteDataSource.updateProfile(profile: profile)
            return updatedProfile
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch (Single)

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
            throw ProfileError.notFound("Failed to find profile with ID \(id): \(error.localizedDescription)")
        }
    }
    
    /// Retrieves the currently authenticated profile.
    ///
    /// - Returns: A `Profile` object representing the current authenticated user.
    /// - Throws:
    ///   - `ProfileError.notFound`: If no valid authenticated user or profile is found.
    ///   - `ProfileError`: For other errors during the fetch operation.
    public func getCurrentProfile() async throws -> Profile {
        do {
            return try await remoteDataSource.getCurrentProfile()
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.notFound("Failed to collect current profile: \(error.localizedDescription)")
        }
    }

    // MARK: - List / Search

    /// Lists profiles based on optional filter criteria.
    ///
    /// - Parameters:
    ///   - id: An optional filter for the profile's ID.
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
                musterId: musterId
            )
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.fetchFailed("Failed to fetch profiles: \(error.localizedDescription)")
        }
    }

    // MARK: - Auth

    /// Registers a new user account with an email and password, returning the newly registered user's ID (UID).
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object containing the user's data.
    ///   - password: The password for the new user account.
    /// - Returns: The updated `Profile` object
    /// - Throws:
    ///   - `ProfileError.creationFailed`: If registration fails.
    ///   - `ProfileError`: For other errors during the registration process.
    public func registerWithEmail(profile: Profile, password: String) async throws -> Profile {
        do {
            let updatedProfile = try await remoteDataSource.registerWithEmail(profile: profile, password: password)
            return updatedProfile
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.creationFailed("Failed to register profile: \(error.localizedDescription)")
        }
    }

    /// Signs in an existing user with an email and password, returning the authenticated `Profile`.
    ///
    /// - Parameters:
    ///   - profile: A `Profile` containing at least the user's email.
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the authenticated user.
    /// - Throws:
    ///   - `ProfileError.authenticationFailed`: If authentication fails.
    ///   - `ProfileError`: For other errors during sign-in.
    public func signInWithEmail(profile: Profile, password: String) async throws -> Profile {
        do {
            let signedInProfile = try await remoteDataSource.signInWithEmail(profile: profile, password: password)
            return signedInProfile
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.authenticationFailed("Failed to authenticate profile: \(error.localizedDescription)")
        }
    }

    /// Signs out the currently authenticated user.
    ///
    /// - Throws: `ProfileError.signOutFailed` if the sign-out operation fails.
    public func signOut() async throws {
        do {
            try await remoteDataSource.signOut()
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.signOutFailed("Failed to sign out: \(error.localizedDescription)")
        }
    }

    /// Sends a password reset email to the specified address.
    ///
    /// - Parameter email: The email address for which to send a password reset link.
    /// - Throws: `ProfileError.passwordResetFailed` if the reset operation fails.
    public func sendPasswordReset(email: String) async throws {
        do {
            try await remoteDataSource.sendPasswordReset(email: email)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.passwordResetFailed("Failed to reset password: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.deletionFailed`: If the deletion fails.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    ///   - `ProfileError`: For other failures during the deletion operation.
    public func deleteProfile(profile: Profile) async throws {
        do {
            try await remoteDataSource.deleteProfile(profile: profile)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.deletionFailed("Failed to delete profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Terminate

    /// Terminates the currently authenticated user's account by re-authenticating with the provided password
    /// and then deleting the user's Auth record and Firestore profile.
    ///
    /// - Parameter password: The password used for re-authentication before deletion.
    /// - Throws:
    ///   - `ProfileError.authenticationFailed`: If re-authentication fails.
    ///   - `ProfileError.deletionFailed`: If deletion fails.
    ///   - `ProfileError.notFound`: If there is no current user to terminate.
    ///   - `ProfileError`: For other errors during the termination process.
//    public func terminateUser(password: String) async throws {
//        do {
//            try await remoteDataSource.terminateUser(password: password)
//        } catch let error as ProfileError {
//            throw error
//        } catch {
//            throw ProfileError.deletionFailed("Failed to delete user account: \(error.localizedDescription)")
//        }
//    }
}
