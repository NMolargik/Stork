//
//  FirebaseProfileDataSource.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import UIKit

#if !SKIP
import FirebaseStorage
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

#else
import SkipFirebaseStorage
import SkipFirebaseCore
import SkipFirebaseFirestore
import SkipFirebaseAuth
#endif


/// A data source responsible for interacting with the Firebase Firestore database to manage profile records.
public class FirebaseProfileDataSource: ProfileRemoteDataSourceInterface {
    
    /// The Firestore database instance.
    private let db: Firestore
    
    /// The Firebase Auth instance
    private let auth: Auth
    
    /// The Firebase Storage instance
    private let storage: Storage
    
    /// Initializes the FirebaseProfileDataSource with a Firestore instance.
    public init() {
        self.db = Firestore.firestore()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
    }
    
    // MARK: - Retrieve a Single Profile by ID
    
    /// Fetches a single profile by its unique ID.
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
            guard var profile = Profile(from: data) else {
                throw ProfileError.invalidData("Invalid data for profile with ID \(id).")
            }

            // Attempt to retrieve the profile picture
            do {
                let profilePicture = try await self.retrieveProfilePicture(profile)
                profile.profilePicture = profilePicture
            } catch {
                print("No profile picture found for profile with ID \(id): \(error.localizedDescription)")
            }

            return profile
        } catch {
            throw ProfileError.firebaseError("Failed to fetch profile with ID \(id): \(error.localizedDescription)")
        }
    }
    
    public func getCurrentProfile() async throws -> Profile {
        do {
            guard let userId = auth.currentUser?.uid else {
                throw ProfileError.notFound("No profile currently logged in.")
            }

            let document = try await db.collection("Profile").document(userId).getDocument()
            guard let data = document.data() else {
                throw ProfileError.notFound("Profile with ID \(userId) not found.")
            }
            guard var profile = Profile(from: data) else {
                throw ProfileError.invalidData("Invalid data for profile with ID \(userId).")
            }

            // Attempt to retrieve the profile picture
            do {
                let profilePicture = try await self.retrieveProfilePicture(profile)
                profile.profilePicture = profilePicture
            } catch {
                print("No profile picture found for profile with ID \(userId): \(error.localizedDescription)")
            }

            return profile
        } catch {
            throw ProfileError.firebaseError("Failed to fetch current profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - List Profiles with Filters
    
    /// Lists profiles based on optional filters.
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
        musterId: String? = nil,
        isAdmin: Bool? = nil
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
            if let isAdmin = isAdmin { query = query.whereField("isAdmin", isEqualTo: isAdmin) }
            
            // Fetch documents
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { document in
                Profile(from: document.data())
            }
        } catch {
            throw ProfileError.firebaseError("Failed to list profiles: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Create a New Profile
    
    /// Creates a new profile record in Firestore.
    ///
    /// - Parameter profile: The `Profile` object to create.
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If an error occurs while creating the profile.
    public func createProfile(_ profile: Profile) async throws {
        do {
            let data = profile.dictionary
            try await db.collection("Profile").document(profile.id).setData(data)
            
            if profile.profilePicture != nil {
                try await self.uploadProfilePicture(profile)
            }

        } catch {
            throw ProfileError.firebaseError("Failed to create profile: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: - Update an Existing Profile
    
    /// Updates an existing profile record in Firestore.
    ///
    /// - Parameter profile: The `Profile` object containing updated data.
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If an error occurs while updating the profile.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    public func updateProfile(_ profile: Profile) async throws {
        do {
            let data = profile.dictionary
            try await db.collection("Profile").document(profile.id).updateData(data)
        } catch {
            throw ProfileError.firebaseError("Failed to update profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete an Existing Profile
    
    /// Deletes an existing profile record from Firestore.
    ///
    /// - Parameter profile: The `Profile` object to delete.
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If an error occurs while deleting the profile.
    ///   - `ProfileError.notFound`: If the profile does not exist.
    public func deleteProfile(_ profile: Profile, password: String) async throws {
        do {
            try await db.collection("Profile").document(profile.id).delete()
        } catch {
            throw ProfileError.firebaseError("Failed to delete profile: \(error.localizedDescription)")
        }
    }
    
    // AUTHENTICATION
    
    /// Registers a new user account with an email and password, and uploads their profile picture if provided.
    ///
    /// - Parameters:
    ///   - profile: The `Profile` object containing user information, including email and optional profile picture.
    ///   - password: The password for the user's account.
    /// - Returns: The same `Profile` object after successful registration.
    /// - Throws:
    ///   - `ProfileError.firebaseError`: If the registration process fails in Firebase.
    public func registerWithEmail(_ profile: Profile, password: String) async throws -> Profile {
        do {
            let result = try await auth.createUser(withEmail: profile.email, password: password)
            
            var updatedProfile = profile
            updatedProfile.id = result.user.uid
                        
            return updatedProfile
        } catch {
            throw error
        }
    }
    
    /// Signs in an existing user with an email and password, and retrieves their profile.
    ///
    /// - Parameters:
    ///   - profile: A partial `Profile` object containing the user's email.
    ///   - password: The password for the user's account.
    /// - Returns: A `Profile` object representing the authenticated user.
    /// - Throws:
    ///   - `ProfileError.notFound`: If the user's profile is not found in Firestore.
    ///   - `ProfileError.firebaseError`: If the authentication or profile retrieval process fails.
    public func signInWithEmail(_ profile: Profile, password: String) async throws -> Profile {
        do {
            let result = try await auth.signIn(withEmail: profile.email, password: password)
            let firebaseUser = result.user
            
            let document = try await db.collection("Profile").document(firebaseUser.uid).getDocument()
            guard let data = document.data() else {
                throw ProfileError.notFound("Profile not found for user with ID \(firebaseUser.uid).")
            }
            
            guard let userProfile = Profile(from: data) else {
                throw ProfileError.invalidData("Invalid data found for profile with ID \(firebaseUser.uid).")
            }
            
            return userProfile
        } catch {
            throw ProfileError.firebaseError("Failed to sign in with email: \(error.localizedDescription)")
        }
    }
    
    /// Signs out the currently authenticated user.
    ///
    /// - Throws:
    ///   - `ProfileError.signOutFailed`: If the sign-out operation fails.
    public func signOut() async {
        do {
            try auth.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    /// Uploads the profile picture to Firebase Storage for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object containing the profile picture to upload.
    /// - Throws:
    ///   - `NSError`: If the profile picture data is invalid or the upload process fails.
    public func uploadProfilePicture(_ profile: Profile) async throws {
        guard let imageData = profile.profilePicture?.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FirebaseAuthRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile Picture contains invalid data"])
        }
        
        let storageRef = storage.reference().child("profile_pictures/\(profile.email).jpg")
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: nil)
        } catch {
            throw error
        }
    }
    
    /// Retrieves the profile picture from Firebase Storage for the specified profile.
    ///
    /// - Parameter profile: The `Profile` object containing the email used to locate the profile picture.
    /// - Returns: A `UIImage` object representing the profile picture.
    /// - Throws:
    ///   - `NSError`: If the profile picture cannot be retrieved or converted to a `UIImage`.
    public func retrieveProfilePicture(_ profile: Profile) async throws -> UIImage? {
        let storageRef = storage.reference().child("profile_pictures/\(profile.email).jpg")
        
        do {
            throw NSError(domain: "FirebaseProfileDataSource", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve profile picture: "])
        }

//
//        do {
//            let data = try await storageRef.data(maxSize: 5 * 1024 * 1024)
//            guard let image = UIImage(data: data) else {
//                throw NSError(domain: "FirebaseProfileDataSource", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to convert data to UIImage."])
//            }
//
//            return image
//        } catch {
//            throw NSError(domain: "FirebaseProfileDataSource", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve profile picture: \(error.localizedDescription)"])
//        }
    }
    
//    suspend fun retrieveProfilePicture(profile: Profile): Bitmap? {
//           val storageRef = storage.reference.child("profile_pictures/${profile.email}.jpg")
//           return try {
//               // Fetch data from Firebase Storage
//
//               // Convert data to a Bitmap
//               val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size)
//               bitmap ?: throw Exception("Unable to convert data to Bitmap.")
//           } catch (e: Exception) {
//               // Handle errors
//               throw Exception("Failed to retrieve profile picture: ${e.message}", e)
//           }
//       }
    
    public func isAuthenticated() -> Bool {
        return auth.currentUser != nil
    }
    
    public func sendPasswordReset(email: String) async throws {
        return try await auth.sendPasswordReset(withEmail: email)
    }
}
