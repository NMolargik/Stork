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

#if SKIP
import java.util.regex.Pattern
#endif

public class ProfileViewModel: ObservableObject {
    // MARK: - AppStorage
    @AppStorage("appState") private var appState: AppState = .splash
    @AppStorage("loggedIn") var loggedIn = false
    
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
    
    // MARK: - Dependency
    private let profileRepository: ProfileRepositoryInterface
    
    // MARK: - Initializer
    @MainActor
    public init(profileRepository: ProfileRepositoryInterface) {
        self.profileRepository = profileRepository
        self.profile = Profile()
        self.tempProfile = Profile()
    }
    
    // MARK: - Fetch Current Profile
    @MainActor
    public func fetchCurrentProfile() async throws {
        isWorking = true
        do {
            let fetchedProfile = try await profileRepository.getCurrentProfile()
            self.profile = fetchedProfile
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            self.signOut()
            isWorking = false
            throw error
        }
        isWorking = false
    }
    
    // MARK: - Register / Create Profile
    @MainActor
    public func registerWithEmail() async throws {
        // Validate entire registration form first
        validateRegistrationForm()
        guard isFormValid else {
            throw ProfileError.creationFailed("Details are invalid. Please correct the form.")
        }
        
        isWorking = true
        
        do {
            let newProfile = try await profileRepository.registerWithEmail(
                profile: tempProfile,
                password: passwordText
            )
            
            // Update local state with the newly returned Profile
            self.profile = newProfile
            
            self.profile = try await profileRepository.createProfile(profile: profile)
            self.loggedIn = true
            
        } catch {
            self.errorMessage = "Registration failed: \(error.localizedDescription)"
            isWorking = false
            throw error
        }
        
        self.passwordText = ""
        self.confirmPassword = ""
        isWorking = false
    }
    
    
    // MARK: - Fetch profiles
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
        musterId: String? = nil,
        isAdmin: Bool? = nil
    ) async throws -> [Profile] {
        do {
            isWorking = true
            defer { isWorking = false }
            
            let results = try await profileRepository.listProfiles(
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
            
            return results
        } catch {
            self.errorMessage = "Failed to fetch profiles: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Login
    @MainActor
    public func signInWithEmail() async throws {
        guard !profile.email.isEmpty else {
            throw ProfileError.authenticationFailed("Email was not provided.")
        }
        guard !passwordText.isEmpty else {
            throw ProfileError.authenticationFailed("Password was not provided.")
        }
        
        isWorking = true
        
        do {
            let signedInProfile = try await profileRepository.signInWithEmail(
                profile: profile,
                password: passwordText
            )
            self.profile = signedInProfile
            self.loggedIn = true
        } catch {
            self.errorMessage = "Failed to sign in: \(error.localizedDescription)"
            isWorking = false
            throw error
        }
        
        // Attempt to fetch the user’s full profile
        do {
            let currentProfile = try await profileRepository.getCurrentProfile()
            self.profile = currentProfile
        } catch {
            // If we fail to fetch the full profile, sign out
            try await profileRepository.signOut()
            self.errorMessage = "Unable to load profile after sign in."
            isWorking = false
            throw error
        }
        
        isWorking = false
    }
    
    // MARK: - Password Reset
    @MainActor
    public func sendPasswordReset() async throws {
        guard !tempProfile.email.isEmpty else {
            throw ProfileError.passwordResetFailed("No email to send reset.")
        }
        isWorking = true
        
        do {
            try await profileRepository.sendPasswordReset(email: tempProfile.email)
        } catch {
            self.errorMessage = "Password reset failed: \(error.localizedDescription)"
            isWorking = false
            throw error
        }
        
        isWorking = false
    }
    
    // MARK: - Update Profiles
    @MainActor
    public func updateProfile() async throws {
        isWorking = true
        
        do {
            // Validate the form if this is an “editing profile” scenario
            if editingProfile {
                validateProfileForm(tempProfile)
                guard isFormValid else {
                    isWorking = false
                    throw ProfileError.updateFailed("Invalid form data.")
                }
            }
            
            // Actually update the profile
            let updated = try await profileRepository.updateProfile(profile: tempProfile)
            self.profile = updated
        } catch {
            self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
            isWorking = false
            throw error
        }
        
        isWorking = false
    }
    
    @MainActor
    public func updateProfileAdminStatus(profile: Profile) async throws {
        isWorking = true
        
        do {
            _ = try await profileRepository.updateProfile(profile: tempProfile)
        } catch {
            self.errorMessage = "Failed to assign admin: \(error.localizedDescription)"
            isWorking = false
            throw error
        }
        
        isWorking = false
    }
    
    // MARK: - Delete / Terminate
    @MainActor
    public func deleteProfile(password: String) async throws {
        isWorking = true
        
        do {
            try await profileRepository.deleteProfile(profile: profile)
            // Also terminates the user’s Auth account
            //try await profileRepository.terminateUser(password: password)
            resetTempProfile()
            reset()
            signOut()
        } catch {
            self.errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            isWorking = false
            throw error
        }
        
        isWorking = false
    }
    
//    @MainActor
//    public func terminateUser(password: String) async throws {
//        isWorking = true
//        do {
//            try await profileRepository.terminateUser(password: password)
//            resetTempProfile()
//            reset()
//            signOut()
//        } catch {
//            self.errorMessage = "Failed to terminate user: \(error.localizedDescription)"
//            isWorking = false
//            throw error
//        }
//        isWorking = false
//    }
    
    // MARK: - Signing Out
    @MainActor
    public func signOut() {
        isWorking = true
        
        Task {
            do {
                try await profileRepository.signOut()
                self.passwordText = ""
                self.confirmPassword = ""
                self.resetTempProfile()
                self.reset()
                self.loggedIn = false
                self.appState = .splash
            } catch {
                self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
            }
            self.isWorking = false
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
        emailError = isEmailValid(tempProfile.email) ? nil : "Invalid email address"
        passwordError = isPasswordValid(passwordText) ? nil : "Password must be at least 8 chars w/ letter, number, symbol"
        confirmPasswordError = (passwordText == confirmPassword) ? nil : "Passwords do not match"
        firstNameError = isNameValid(tempProfile.firstName) ? nil : "First name cannot be empty"
        lastNameError = isNameValid(tempProfile.lastName) ? nil : "Last name cannot be empty"
        birthdayError = isBirthdayValid(tempProfile.birthday) ? nil : "Must be at least 16 years old"
        
        withAnimation {
            isFormValid =
                emailError == nil &&
                passwordError == nil &&
                confirmPasswordError == nil &&
                firstNameError == nil &&
                lastNameError == nil &&
                birthdayError == nil
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
            role: .nurse,
            isAdmin: false
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
