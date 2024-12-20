//
//  RegisterViewModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI
//import PhotosUI
import StorkModel

#if SKIP
import java.util.regex.Pattern
#endif

class RegisterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var passwordText = ""
    @Published var confirmPassword = ""
    @Published var registrationError: String = ""
    @Published var isFormValid = false

    // Individual field errors
    @Published var emailError: String? = nil
    @Published var passwordError: String? = nil
    @Published var confirmPasswordError: String? = nil
    @Published var firstNameError: String? = nil
    @Published var lastNameError: String? = nil
    @Published var birthdayError: String? = nil
    
    @Published public var profilePicture: UIImage?
    @Published var isWorking: Bool = false
    
    // MARK: - Required Repository
    var profileRepository: ProfileRepositoryInterface

    // MARK: - Initializer
    @MainActor
    public init(profileRepository: ProfileRepositoryInterface) {
        self.profileRepository = profileRepository
    }
    
    @MainActor
    func registerWithEmail(profile: Profile) async throws -> String {
        guard isFormValid else {
            throw ProfileError.creationFailed("Entered details are invalid. Please fill out all fields.")
        }
        
        self.isWorking = true
        
        var uid = ""
        
        do {
            uid = try await profileRepository.registerWithEmail(profile: profile, password: self.passwordText)
            print("Registration succeeded: \(profile.email)")
        } catch {
            self.isWorking = false
            throw ProfileError.creationFailed(error.localizedDescription)
        }
        
        do {
            var updatedProfile = profile
            updatedProfile.id = uid
            
            try await self.createProfile(profile: updatedProfile)
            print("Created profile for \(profile.firstName) \(profile.lastName)")
            self.isWorking = false
            return uid
        } catch {
            self.isWorking = false
            try await profileRepository.signOut()
            throw ProfileError.creationFailed(error.localizedDescription)
        }
        
        //TODO: if there is a profile picture, upload it

    }
    
    private func uploadProfilePicture(profile: Profile) async throws {
        guard let profilePicture else { return }
        
        do {
            try await profileRepository.uploadProfilePicture(profile: profile, profilePicture: profilePicture)
        } catch {
            throw ProfileError.creationFailed(error.localizedDescription)
        }
    }
    
    private func createProfile(profile: Profile) async throws {
        do {
            try await profileRepository.createProfile(profile: profile)
        }
    }
    
    func validateForm(profile: Profile) {
        emailError = isEmailValid(email: profile.email) ? nil : "Invalid email address"
        passwordError = isPasswordValid(password: passwordText) ? nil : "Password must be at least 8 characters and include a letter, number, and symbol"
        confirmPasswordError = passwordText == confirmPassword ? nil : "Passwords do not match"
        firstNameError = isNameValid(name: profile.firstName) ? nil : "First name cannot be empty"
        lastNameError = isNameValid(name: profile.lastName) ? nil : "Last name cannot be empty"
        birthdayError = isBirthdayValid(birthday:profile.birthday) ? nil : "Please select a valid birthday. You should be at least 16."
        
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

    private func isEmailValid(email: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        #if !SKIP
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: email)
        #else
        let emailPattern = Pattern.compile(emailFormat)
        return emailPattern.matcher(email).matches()
        #endif
    }
        
    private func isPasswordValid(password: String) -> Bool {
        let passwordFormat = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[\\Q!@#$%^&*()_+=<>?{}[]~`|/.,:;-\\E])[A-Za-z\\d\\Q!@#$%^&*()_+=<>?{}[]~`|/.,:;-\\E]{8,}$"
        
        #if !SKIP
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordFormat)
        return passwordPredicate.evaluate(with: password)
        #else
        let passwordPattern = Pattern.compile(passwordFormat)
        return passwordPattern.matcher(password).matches()
        #endif
    }

    private func isNameValid(name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func isBirthdayValid(birthday: Date) -> Bool {
        guard let sixteenYearsAgo = Calendar.current.date(byAdding: .year, value: -16, to: Date()) else {
            return false
        }
        return birthday <= sixteenYearsAgo
    }
    
    func onFieldsChanged(profile: Profile) {
        validateForm(profile: profile)
    }
}
