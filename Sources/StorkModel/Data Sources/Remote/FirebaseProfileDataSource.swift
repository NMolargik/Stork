//
//  FirebaseProfileDataSource.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import UIKit

#if !SKIP
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
#else
import SkipFirebaseCore
import SkipFirebaseFirestore
import SkipFirebaseAuth
#endif

/// A data source responsible for interacting with the Firebase Firestore database to manage profile records.
public class FirebaseProfileDataSource: ProfileRemoteDataSourceInterface {
    
    // MARK: - Dependencies
    
    /// The Firestore database instance.
    private let db: Firestore
    
    /// The Firebase Auth instance
    private let auth: Auth
    
    // MARK: - Initialization
    
    /// Initializes the FirebaseProfileDataSource with Firestore, Auth, and Storage instances.
    public init() {
        self.db = Firestore.firestore()
        self.auth = Auth.auth()
    }
    
    // MARK: - Create a New Profile
    
    /// Creates a new profile record in Firestore and returns the newly created `Profile`.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Returns: The newly created `Profile` (including the `id` if needed).
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If an error occurs while creating the profile.
    public func createProfile(profile: Profile) async throws -> Profile {
        do {
            // Convert to dictionary
            let data = profile.dictionary
            // Write to Firestore at document ID = profile.id (if you're setting that manually).
            try await db.collection("Profile").document(profile.id).setData(data)
            
            // Return the same profile (or optionally re-fetch if needed).
            return profile
        } catch {
            throw ProfileError.creationFailed("Failed to create profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update an Existing Profile
    
    /// Updates an existing profile record in Firestore and returns the updated `Profile`.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Returns: The updated `Profile`.
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If an error occurs while updating the profile.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    public func updateProfile(profile: Profile) async throws -> Profile {
        do {
            let data = profile.dictionary
            try await db.collection("Profile").document(profile.id).updateData(data)
            
            return profile
        } catch {
            throw ProfileError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Retrieve a Single Profile by ID
    
    /// Fetches a single profile by its unique ID, returning a non-optional `Profile` or throwing if not found.
    ///
    /// - Parameter id: The unique ID of the profile to fetch.
    /// - Returns: A `Profile` object representing the profile with the specified ID.
    /// - Throws:
    ///   - `ProfileError.notFound`: If no profile with the specified ID is found.
    ///   - `ProfileError.firebaseError`: If an error occurs while fetching the profile.
    public func getProfile(byId id: String) async throws -> Profile {
        do {
            let document = try await db.collection("Profile").document(id).getDocument()
            guard let data = document.data() else {
                throw ProfileError.notFound("Profile with ID \(id) not found.")
            }
            guard let profile = Profile(from: data) else {
                throw ProfileError.notFound("Invalid data for profile with ID \(id).")
            }
            return profile
        } catch {
            throw ProfileError.fetchFailed("Failed to fetch profile with ID \(id): \(error.localizedDescription)")
        }
    }
    
    /// Retrieves the currently authenticated profile, returning a non-optional `Profile` or throwing if not found.
    ///
    /// - Returns: A `Profile` object representing the current authenticated user's profile.
    /// - Throws:
    ///   - `ProfileError.notFound`: If there is no currently logged-in user or their profile doesn't exist.
    ///   - `ProfileError.firebaseError`: If any error occurs while fetching the profile.
    public func getCurrentProfile() async throws -> Profile {
        do {
            guard let userId = auth.currentUser?.uid else {
                // Optionally sign out if no valid user
                try? auth.signOut()
                throw ProfileError.notFound("No profile currently logged in.")
            }

            let document = try await db.collection("Profile").document(userId).getDocument()
            guard let data = document.data() else {
                throw ProfileError.notFound("Profile with ID \(userId) not found.")
            }
            
            guard let profile = Profile(from: data) else {
                throw ProfileError.notFound("Invalid data for profile with ID \(userId).")
            }
            return profile
        } catch {
            throw ProfileError.fetchFailed("Failed to retrieve the current profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - List Profiles with Filters
    
    /// Lists profiles based on optional filters.
    ///
    /// - Parameters:
    ///   - id: An optional filter for the profile's `id`.
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
    ///   - `ProfileError.firebaseError`: If an error occurs while fetching profiles.
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
            var query: Query = db.collection("Profile")
            
            // Apply optional filters
            if let id = id { query = query.whereField("id", isEqualTo: id) }
            if let firstName = firstName { query = query.whereField("firstName", isEqualTo: firstName) }
            if let lastName = lastName { query = query.whereField("lastName", isEqualTo: lastName) }
            if let email = email { query = query.whereField("email", isEqualTo: email) }
            if let birthday = birthday {
                query = query.whereField("birthday", isEqualTo: birthday.timeIntervalSince1970)
            }
            if let role = role { query = query.whereField("role", isEqualTo: role.rawValue) }
            if let primaryHospital = primaryHospital {
                query = query.whereField("primaryHospital", isEqualTo: primaryHospital)
            }
            if let musterId = musterId { query = query.whereField("musterId", isEqualTo: musterId) }
            if let joinDate = joinDate {
                query = query.whereField("joinDate", isEqualTo: joinDate.timeIntervalSince1970)
            }
            
            // Fetch documents
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { doc in
                Profile(from: doc.data())
            }
        } catch {
            throw ProfileError.fetchFailed("Failed to list profiles: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete an Existing Profile
    
    /// Deletes an existing profile record from Firestore.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If an error occurs while deleting the profile.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    public func deleteProfile(profile: Profile) async throws {
        do {
            try await db.collection("Profile").document(profile.id).delete()
        } catch {
            throw ProfileError.deletionFailed("Failed to delete profile with ID \(profile.id): \(error.localizedDescription)")
        }
    }
    
    // MARK: - AUTHENTICATION
    
    /// Registers a new user account with an email and password, returning the newly registered profile's UID or entire Profile.
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object containing user information, including email.
    ///   - password: The password for the user's account.
    /// - Returns: The newly registered user’s UID (or a `Profile`, if you prefer).
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If the registration process fails in Firebase.
    public func registerWithEmail(profile: Profile, password: String) async throws -> Profile {
        do {
            let result = try await auth.createUser(withEmail: profile.email, password: password)
            var updatedProfile = profile
            updatedProfile.id = result.user.uid
            return updatedProfile
        } catch {
            throw ProfileError.creationFailed("Failed to register with email: \(error.localizedDescription)")
        }
    }
    
    /// Signs in an existing user with an email and password, returning the associated `Profile`.
    ///
    /// - Parameters:
    ///   - profile: A partial `Profile` object containing the user's email.
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the authenticated user.
    /// - Throws:
    ///   - `ProfileError.authenticationFailed`: If authentication or profile retrieval fails.
    public func signInWithEmail(profile: Profile, password: String) async throws -> Profile {
        do {
            let result = try await auth.signIn(withEmail: profile.email, password: password)
            let firebaseUser = result.user
            
            let document = try await db.collection("Profile").document(firebaseUser.uid).getDocument()
            guard let data = document.data() else {
                throw ProfileError.notFound("No profile found for user with ID \(firebaseUser.uid).")
            }
            guard let fullProfile = Profile(from: data) else {
                throw ProfileError.authenticationFailed("Invalid data for profile with ID \(firebaseUser.uid).")
            }
            
            return fullProfile
        } catch {
            throw ProfileError.authenticationFailed("Failed to sign in with email: \(error.localizedDescription)")
        }
    }
    
//    /// Re-authenticates the currently logged-in user with the given password.
//    /// - Throws:
//    ///   - `ProfileError.authenticationFailed` if re-auth fails.
//    public func reauthenticateUser(password: String) async throws {
//        guard let user = auth.currentUser else {
//            throw ProfileError.notFound("No current user found. Cannot re-authenticate.")
//        }
//        guard let email = user.email else {
//            throw ProfileError.notFound("Current user has no email; cannot re-authenticate.")
//        }
//        //TODO: Future Skip contribution
//
////        let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email, password: password)
////
////        do {
////            try await user.reauthenticate(with: credential)
////        } catch {
////            throw ProfileError.authenticationFailed("Failed to re-authenticate user: \(error.localizedDescription)")
////        }
//    }
    
    /// Signs out the currently authenticated user.
    ///
    /// - Throws:
    ///   - `ProfileError.signOutFailed`: If the sign-out operation fails.
    public func signOut() async throws {
        do {
            try auth.signOut()
        } catch {
            throw ProfileError.signOutFailed("Error signing out: \(error.localizedDescription)")
        }
    }
    
    /// Checks whether a user is currently authenticated.
    ///
    /// - Returns: `true` if a user is logged in, `false` otherwise.
    public func isAuthenticated() -> Bool {
        return auth.currentUser != nil
    }
    
    /// Sends a password reset email to the specified address.
    ///
    /// - Parameter email: The email address to send a password reset link to.
    /// - Throws: `ProfileError.firebaseError` if the reset fails.
    public func sendPasswordReset(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw ProfileError.passwordResetFailed("Failed to send password reset: \(error.localizedDescription)")
        }
    }
    
//    // MARK: - Terminate User (Requires Recent Re-Authentication)
//
//    /// Terminates the currently authenticated user's account by re-authenticating with the provided password
//    /// and then deleting the user from Firebase Auth and Firestore.
//    ///
//    /// - Parameter password: The password used to re-authenticate before account termination.
//    /// - Throws:
//    ///   - `ProfileError.authenticationFailed`: If re-authentication fails.
//    ///   - `ProfileError.deletionFailed`: If the account deletion fails.
//    ///   - `ProfileError.notFound`: If there's no current user.
//    public func terminateUser(password: String) async throws {
//        // Make sure we have a current user
//        guard let user = auth.currentUser else {
//            throw ProfileError.notFound("No current user found. Cannot terminate.")
//        }
//        // Make sure user has a valid email
//        guard let email = user.email else {
//            throw ProfileError.notFound("Current user has no email. Cannot re-authenticate.")
//        }
//    
//        
//        // 1) Re-authenticate with the provided password
//        
//        //TODO: Future Skip contribution
////        let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email, password: password)
////        do {
////            // Must succeed to allow deletion
////            try await user.reauthenticate(with: credential)
////        } catch {
////            throw ProfileError.authenticationFailed("Re-authentication failed: \(error.localizedDescription)")
////        }
//        
//        
//        try await user.delete()
//        
//        
//        
//        // 2) Delete Firebase Auth user
//        //TODO: awaiting Skip support
//        
////        do {
////            try await user.delete()
////        } catch {
////            throw ProfileError.deletionFailed("Failed to delete user from Auth: \(error.localizedDescription)")
////        }
//        
//        // 3) Also delete the user’s profile document in Firestore
//        do {
//            try await db.collection("Profile").document(user.uid).delete()
//        } catch {
//            throw ProfileError.deletionFailed("Failed to delete user’s profile document: \(error.localizedDescription)")
//        }
//    }
}
