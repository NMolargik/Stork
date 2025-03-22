//
//  ProfileViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 11/8/24.
//

import Foundation
import Combine
import SwiftUI
import StorkModel
import SkipRevenueCat

#if !SKIP
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
#else
import java.util.regex.Pattern
import SkipFirebaseCore
import SkipFirebaseFirestore
import SkipFirebaseAuth
#endif

public class ProfileViewModel: ObservableObject {
    // MARK: - Published Core State
    @Published var profile: Profile
    @Published var tempProfile: Profile
    
    // MARK: - Published Error/Loading States
    @Published var errorMessage: String?
    @Published var isWorking: Bool = false
    @Published var editingProfile: Bool = false
    
    // MARK: - Validation States
    @Published var isFormValid = false
    @Published var firstNameError: String? = nil
    @Published var lastNameError: String? = nil
    @Published var birthdayError: String? = nil
    
    // MARK: - Registration & Login Fields
    @Published var emailError: String? = nil
    @Published var passwordText: String = ""
    @Published var passwordError: String? = nil
    @Published var confirmPassword: String = ""
    @Published var confirmPasswordError: String? = nil
    
    @Published var hasAttemptedSubmit: Bool = false
    
    // MARK: - Dependency
    private let profileRepository: ProfileRepositoryInterface
    
    private let appStorageManager: AppStorageManager


    
    // MARK: - Initializer
    @MainActor
    public init(profileRepository: ProfileRepositoryInterface, appStorageManager: AppStorageManager) {
        self.profileRepository = profileRepository
        self.appStorageManager = appStorageManager
        self.profile = Profile()
        self.tempProfile = Profile()
    }
    
    // MARK: - Fetch Current Profile
    @MainActor
    public func fetchCurrentProfile() async throws {
        print("Fetching profile")
        isWorking = true
        defer { isWorking = false }
        
        do {
            let fetchedProfile = try await profileRepository.getCurrentProfile()
            print("Done fetching profile")
            self.profile = fetchedProfile
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            // Sign out if fetching fails, to clear state
            self.signOut()
            throw error
        }
    }
    
    // MARK: - Register / Create Profile
    @MainActor
    public func registerWithEmail() async throws {
        hasAttemptedSubmit = true
        // 1) Validate entire registration form
        validateRegistrationForm()
        guard isFormValid else {
            throw ProfileError.creationFailed("Some fields are invalid. Please try again.")
        }
        
        // 2) Show loading indicator
        isWorking = true
        defer { isWorking = false }
        
        do {
            // Step A) Register user with email/password
            let newProfile = try await profileRepository.registerWithEmail(
                profile: tempProfile,
                password: passwordText
            )
            
            // Step B) Overwrite self.profile with returned profile
            self.profile = newProfile
            
            // Step C) Also explicitly create the profile in Firestore (if your logic requires it)
            self.profile = try await profileRepository.createProfile(profile: profile)
            
            // Mark user as logged in
//            self.loggedIn = true
            
        } catch {
            self.errorMessage = "Registration failed: \(error.localizedDescription)"
            throw error
        }
        
        // Clear sensitive fields
        self.passwordText = ""
        self.confirmPassword = ""
    }
    
    // MARK: - Fetch Profiles (Generic List)
    @MainActor
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
        isWorking = true
        defer { isWorking = false }
        
        do {
            return try await profileRepository.listProfiles(
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
        } catch {
            self.errorMessage = "Failed to fetch profiles: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Login
    @MainActor
    public func signInWithEmail() async throws {
        // Basic validation
        guard !profile.email.isEmpty else {
            throw ProfileError.authenticationFailed("An email address was not provided.")
        }
        guard !passwordText.isEmpty else {
            throw ProfileError.authenticationFailed("A password was not provided.")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        do {
            // Step 1) Sign in with email/password
            let signedInProfile = try await profileRepository.signInWithEmail(profile: profile, password: passwordText)
            self.profile = signedInProfile
            print("found profile: \(self.profile.id)")
//            self.loggedIn = true
            
            // Step 2) Attempt to fetch the user’s full profile (if separate)
            let currentProfile = try await profileRepository.getCurrentProfile()
            print("gathering full profile: \(self.profile.id)")
            self.profile = currentProfile
            
        } catch {
            // If sign-in fails or fetching the full profile fails, sign out to clear state
            self.errorMessage = "Failed to sign in: \(error.localizedDescription)"
            try? await profileRepository.signOut()
            throw error
        }
    }
    
    // MARK: - Password Reset
    @MainActor
    public func sendPasswordReset() async throws {
        // Ensure we have an email in tempProfile
        guard !tempProfile.email.isEmpty else {
            throw ProfileError.passwordResetFailed("No email to send reset.")
        }
        
        isWorking = true
        defer { isWorking = false }
        
        do {
            try await profileRepository.sendPasswordReset(email: tempProfile.email)
        } catch {
            self.errorMessage = "Password reset failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Update Profile
    @MainActor
    public func updateProfile() async throws {
        isWorking = true
        defer { isWorking = false }
        
        do {
            // If editing, validate the form
            if editingProfile {
                validateProfileForm(tempProfile)
                guard isFormValid else {
                    throw ProfileError.updateFailed("Invalid form data.")
                }
            }
            
            // Actually update the profile
            let updated = try await profileRepository.updateProfile(profile: tempProfile)
            self.profile = updated
            
        } catch {
            self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
            print("profile: \(self.profile.id)")
            throw error
        }
    }
    
    /// Example of an “admin status” update call. If you need more logic, it can go here.
    @MainActor
    public func updateProfileAdminStatus(profile: Profile) async throws {
        isWorking = true
        defer { isWorking = false }
        
        do {
            _ = try await profileRepository.updateProfile(profile: tempProfile)
        } catch {
            self.errorMessage = "Failed to assign admin: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Delete / Terminate
    @MainActor
    public func deleteProfile(password: String) async throws {
        isWorking = true
        defer { isWorking = false }
        
        do {
            // Delete the user’s profile
            try await profileRepository.deleteProfile(profile: profile)
            
            resetTempProfile()
            appStorageManager.isOnboardingComplete = false
            reset()
            let _ = Purchases.sharedInstance.logOut(onError: {_ in }, onSuccess: {_ in })
            signOut()
            
        } catch {
            self.errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Signing Out
    @MainActor
    public func signOut() {
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                try await profileRepository.signOut()
                self.passwordText = ""
                self.confirmPassword = ""
                self.resetTempProfile()
                self.reset()
                appStorageManager.isOnboardingComplete = false
                DispatchQueue.main.async {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("could not sign out")
                    }
                    AppStateManager.shared.currentAppScreen = AppScreen.splash
                    
                    RootView().checkAppState()
                }
                print("Set app screen to splash")
            } catch {
                self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Form Validation
    func validateProfileForm(_ profile: Profile) {
        firstNameError = isNameValid(profile.firstName) ? nil : "First name cannot be empty"
        lastNameError = isNameValid(profile.lastName) ? nil : "Last name cannot be empty"
        birthdayError = isBirthdayValid(profile.birthday) ? nil : "Please select a valid birthday (16+)."
        
        withAnimation {
            isFormValid =
                firstNameError == nil &&
                lastNameError == nil &&
                birthdayError == nil
        }
    }
    
    func validateRegistrationForm() {
        if hasAttemptedSubmit {
            emailError = isEmailValid(tempProfile.email) ? nil : "Invalid email address"
            passwordError = isPasswordValid(passwordText) ? nil : "Password must be at least 8 chars w/ letter, number, symbol"
            firstNameError = isNameValid(tempProfile.firstName) ? nil : "First name cannot be empty"
            lastNameError = isNameValid(tempProfile.lastName) ? nil : "Last name cannot be empty"
            birthdayError = isBirthdayValid(tempProfile.birthday) ? nil : "You must be at least 16 years old to use Stork"
        } else {
            emailError = nil
            passwordError = nil
            firstNameError = nil
            lastNameError = nil
            birthdayError = nil
        }
        // Always validate confirm password immediately if it is not empty and does not match
        confirmPasswordError = (!confirmPassword.isEmpty && passwordText != confirmPassword) ? "Passwords do not match" : nil

        withAnimation {
            isFormValid = (emailError == nil) &&
                          (passwordError == nil) &&
                          (confirmPasswordError == nil) &&
                          (firstNameError == nil) &&
                          (lastNameError == nil) &&
                          (birthdayError == nil)
        }
    }
    
    // MARK: - Helper: Reset
    func resetTempProfile() {
        self.tempProfile = Profile(
            id: UUID().uuidString,
            primaryHospitalId: "",
            musterId: "",
            firstName: "",
            lastName: "",
            email: "",
            birthday: Date(),
            joinDate: Date().description,
            role: .nurse
        )
    }

    func reset() {
        profile = Profile()
        errorMessage = nil
        isFormValid = false
        passwordText = ""
        confirmPassword = ""
    }
    
    // MARK: - Validation Helpers
    private func isNameValid(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func isBirthdayValid(_ birthday: Date) -> Bool {
        guard let minDate = Calendar.current.date(byAdding: .year, value: -16, to: Date()) else { return false }
        return birthday <= minDate
    }
    
    func isEmailValid(_ email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        #if !SKIP
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return predicate.evaluate(with: email)
        #else
        let emailPattern = Pattern.compile(emailFormat)
        return emailPattern.matcher(email).matches()
        #endif
    }
    
    private func isPasswordValid(_ password: String) -> Bool {
        let passwordFormat = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[\\Q!@#$%^&*()_+=<>?{}[]~`|/.,:;-\\E])[A-Za-z\\d\\Q!@#$%^&*()_+=<>?{}[]~`|/.,:;-\\E]{8,}$"
        #if !SKIP
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordFormat)
        return predicate.evaluate(with: password)
        #else
        let passwordPattern = Pattern.compile(passwordFormat)
        return passwordPattern.matcher(password).matches()
        #endif
    }
}
