////
////  LoginViewModel.swift
////
////
////  Created by Nick Molargik on 11/4/24.
////
//
//import Foundation
//import SwiftUI
//import StorkModel
//
//class LoginViewModel: ObservableObject {    
//    // MARK: - Published Properties
//    @Published var password: String = ""
//    @Published var loginError: String = ""
//    @Published var isWorking: Bool = false
//    @Published var profile: Profile = Profile()
//    @Published var showPasswordResetSheet: Bool = false
//    
//    var profileRepository: ProfileRepositoryInterface
//
//    // MARK: - Initializer
//    @MainActor
//    public init(profileRepository: ProfileRepositoryInterface) {
//        self.profileRepository = profileRepository
//    }
//    
//    // MARK: - Methods
//    
//    @MainActor
//    // Attempts to log user in, then retrieve their profile
//    func signInWithEmail() async throws {
//        guard !profile.email.isEmpty else {
//            throw ProfileError.creationFailed("No email was provided")
//        }
//
//        guard !password.isEmpty else {
//            throw ProfileError.creationFailed("No password was provided")
//        }
//
//        self.isWorking = true
//
//        do {
//            try await profileRepository.signInWithEmail(profile: self.profile, password: password)
//            print("Login succeeded: \(profile.email)")
//        } catch {
//            self.isWorking = false
//            throw ProfileError.authenticationFailed(error.localizedDescription)
//        }
//        
//        do {
//            try await self.getCurrentUser()
//            print("Fetched profile for: \(profile.firstName) \(profile.lastName)")
//            self.isWorking = false
//        } catch {
//            self.isWorking = false
//            try await profileRepository.signOut()
//            throw ProfileError.notFound(error.localizedDescription)
//        }
//    }
//    
//    private func getCurrentUser() async throws {
//        do {
//            let fetchedProfile = try await profileRepository.getCurrentProfile()
//            self.profile = fetchedProfile
//        }
//    }
//    
//    func sendPasswordReset() async throws {
//        self.isWorking = true
//        
//        do {
//            try await profileRepository.sendPasswordReset(email: self.profile.email)
//            print("Password reset request sent")
//            self.isWorking = false
//        } catch {
//            self.isWorking = false
//            throw ProfileError.passwordResetFailed(error.localizedDescription)
//        }
//    }
//}
