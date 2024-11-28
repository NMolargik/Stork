//
//  LoginViewModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
import SwiftUI

class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var password: String = ""
    @Published var loginError: String = ""
    @Published var isWorking: Bool = false
    //@Published var profile: Profile = Profile()
    @Published var showPasswordResetSheet: Bool = false
    
//    // MARK: - Login Logic
//    @MainActor
//    func loginWithEmail(profileRepository: ProfileRepository) async throws {
//        guard !profile.email.isEmpty else {
//            throw ProfileError.missingEmail("No email was provided")
//        }
//
//        guard !password.isEmpty else {
//            throw ProfileError.missingPassword("No password was provided")
//        }
//
//        self.isWorking = true
//        self.loginProfileUseCase = LoginProfileUseCase(profileRepository: profileRepository)
//
//        do {
//            if let loggedInProfile = try await loginProfileUseCase?.execute(profile: profile, password: password) {
//                self.profile = loggedInProfile
//                self.isWorking = false
//                print("Login succeeded: \(loggedInProfile.firstName) \(loggedInProfile.lastName)")
//            } else {
//                self.isWorking = false
//                throw ProfileError.firebaseError("There was a login error. Please try again.")
//            }
//        } catch {
//            self.isWorking = false
//            throw ProfileError.firebaseError("Failed to log in. Please try again!")
//        }
//    }
//    
//    func sendPasswordReset(profileRepository: ProfileRepository, email: String) async throws -> String {
//        self.isWorking = true
//        self.resetProfilePasswordUseCase = ResetProfilePasswordUseCase(profileRepository: profileRepository)
//        
//        do {
//            try await resetProfilePasswordUseCase?.execute(email: email)
//            self.isWorking = false
//            return "Email Sent"
//        } catch {
//            self.isWorking = false
//            return "Error sending reset email. Please try again later."
//        }
//    }
//    
//    func handleLoginError(error: ProfileError) {
//        self.loginError = error.description
//        print("Login failed: \(error)")
//        startClearLoginError()
//    }
//    
//    private func startClearLoginError() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            self.loginError = ""
//        }
//    }
}
