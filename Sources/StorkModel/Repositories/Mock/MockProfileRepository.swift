//
//  MockProfileRepository.swift
//
//
//  Created by Nick Molargik on 11/20/24.
//

import Foundation
import SwiftUI

/// A mock implementation of the `ProfileRepositoryInterface` protocol for testing purposes.
public class MockProfileRepository: ProfileRepositoryInterface {
    // MARK: - Properties

    /// A list of mock profiles used for in-memory storage.
    private var profiles: [Profile]

    /// A dictionary to simulate profile picture storage in-memory.
    private var profilePictures: [String: UIImage] = [:]

    // MARK: - Initializer

    /// Initializes the mock repository with optional sample data.
    ///
    /// - Parameter profiles: An array of `Profile` objects to initialize the repository with.
    ///   Defaults to an empty array.
    public init(profiles: [Profile] = []) {
        self.profiles = profiles
    }

    // MARK: - Methods

    /// Fetches a single profile by its unique ID.
    ///
    /// - Parameter id: The unique ID of the profile to fetch.
    /// - Returns: A `Profile` object representing the fetched profile.
    /// - Throws: `ProfileError.notFound` if no profile with the specified ID exists.
    public func getProfile(byId id: String) async throws -> Profile {
        guard let profile = profiles.first(where: { $0.id == id }) else {
            throw ProfileError.notFound("Profile with ID \(id) not found.")
        }
        return profile
    }
    
    public func getCurrentProfile() async throws -> Profile {
        guard let profile = profiles.first else {
            throw ProfileError.notFound("No profile is currently logged in.")
        }
        
        return profile
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
    ///   - profilePictureURL: An optional filter for the profile's picture URL.
    ///   - primaryHospital: An optional filter for the profile's primary hospital ID.
    ///   - joinDate: An optional filter for the profile's join date.
    ///   - musterId: An optional filter for the muster ID associated with the profile.
    ///   - isAdmin: An optional filter for whether the profile has admin privileges.
    /// - Returns: An array of `Profile` objects matching the specified filters.
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
        return profiles
    }

    /// Creates a new profile.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Throws: `ProfileError.creationFailed` if a profile with the same ID already exists.
    public func createProfile(_ profile: Profile) async throws {
        if profiles.contains(where: { $0.id == profile.id }) {
            throw ProfileError.creationFailed("Profile with ID \(profile.id) already exists.")
        }
        profiles.append(profile)
    }

    /// Updates an existing profile.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Throws: `ProfileError.notFound` if the profile does not exist.
    public func updateProfile(_ profile: Profile) async throws {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            throw ProfileError.notFound("Profile with ID \(profile.id) not found.")
        }
        profiles[index] = profile
    }

    /// Deletes an existing profile.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws: `ProfileError.deletionFailed` if the profile does not exist.
    public func deleteProfile(_ profile: Profile, password: String) async throws {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            throw ProfileError.deletionFailed("Failed to delete profile with ID \(profile.id).")
        }
        profiles.remove(at: index)
        profilePictures.removeValue(forKey: profile.id)
    }

    /// Uploads a profile picture for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object containing the profile picture to upload.
    public func uploadProfilePicture(_ profile: Profile) async throws {
        guard let image = profile.profilePicture else {
            throw ProfileError.creationFailed("No profile picture provided for profile with ID \(profile.id).")
        }
        profilePictures[profile.id] = image
    }

    /// Retrieves the profile picture for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object containing the reference to the image.
    /// - Returns: A `UIImage` object representing the profile picture.
    public func retrieveProfilePicture(_ profile: Profile) async throws -> UIImage? {
        guard let image = profilePictures[profile.id] else {
            throw ProfileError.notFound("Profile picture for ID \(profile.id) not found.")
        }
        return image
    }
    
    public func isAuthenticated() -> Bool {
        return true
    }

    public func registerWithEmail(_ profile: Profile, password: String) async throws -> Profile {
        profiles.append(profile)
        return profile
    }
    
    public func signInWithEmail(_ profile: Profile, password: String) async throws -> Profile {
        profiles.append(profile)
        return profile
    }
    
    public func signOut() async {
        profiles.removeAll()
    }
    
    public func sendPasswordReset(email: String) async throws {
        return
    }
}
