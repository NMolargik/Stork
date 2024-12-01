//
//  LoginViewModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI
import StorkModel

class LoginViewModel: ObservableObject {    
    // MARK: - Published Properties
    @Published var password: String = ""
    @Published var loginError: String = ""
    @Published var isWorking: Bool = false
    @Published var profile: Profile = Profile(thisIsTemporary: true)
    @Published var showPasswordResetSheet: Bool = false
    
//    // MARK: - Login Logic
    @MainActor
    func loginWithEmail(profileRepository: ProfileRepositoryInterface) async throws {
        guard !profile.email.isEmpty else {
            throw ProfileError.creationFailed("No email was provided")
        }

        guard !password.isEmpty else {
            throw ProfileError.creationFailed("No password was provided")
        }

        self.isWorking = true

        do {
            let loggedInProfile = try await profileRepository.signInWithEmail(profile, password: password)
            self.profile = loggedInProfile
            self.isWorking = false
            print("Login succeeded: \(loggedInProfile.firstName) \(loggedInProfile.lastName)")
        } catch {
            self.isWorking = false
            throw ProfileError.authenticationFailed("Failed to log in. Please try again!")
        }
    }
    
    func sendPasswordReset(profileRepository: ProfileRepositoryInterface, email: String) async throws -> String {
        self.isWorking = true
        
        do {
            try await profileRepository.sendPasswordReset(email: email)
            self.isWorking = false
            return "Email Sent"
        } catch {
            self.isWorking = false
            return "Error sending reset email. Please try again later."
        }
    }
}
