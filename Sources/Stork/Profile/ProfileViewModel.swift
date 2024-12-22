//
//  ProfileViewModel.swift
//
//  Created by Nick Molargik on 11/8/24.
//

import Foundation
import Combine
import SwiftUI
import StorkModel

public class ProfileViewModel: ObservableObject {
    @AppStorage("appState") private var appState: AppState = AppState.splash
    @AppStorage("loggedIn") var loggedIn = false

    @Published var profile: Profile
    @Published var tempProfile: Profile
    @Published var errorMessage: String?
    @Published var isWorking: Bool = false

    let profileRepository: ProfileRepositoryInterface

    @MainActor
    // Initializer
    public init(profileRepository: ProfileRepositoryInterface) {
        self.profileRepository = profileRepository
        self.profile = Profile()
        self.tempProfile = Profile()
    }

    @MainActor
    // Fetch the current profile asynchronously
    func fetchCurrentProfile() async throws {
        isWorking = true

        do {
            let fetchedProfile = try await profileRepository.getCurrentProfile()
            self.profile = fetchedProfile
            self.isWorking = false
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            self.isWorking = false
            self.signOut()
            throw error
        }
    }
    
    func updateMuster(musterId: String) async throws {
        isWorking = true
        
        var tempProfile = self.profile
        tempProfile.musterId = musterId
        
        Task {
            do {
                try await self.updateProfile()
            } catch {
                throw error
            }
        }
    }
    
    func searchProfilesByMuster(musterId: String) async throws -> [Profile] {
        do {
            return try await profileRepository.listProfiles(id: nil, firstName: nil, lastName: nil, email: nil, birthday: nil, role: nil, primaryHospital: nil, joinDate: nil, musterId: musterId, isAdmin: nil)
        } catch {
            throw error
        }
    }
    
    func resetTempProfile() {
        self.tempProfile = Profile(id: UUID().uuidString, primaryHospitalId: "", musterId: "", firstName: "", lastName: "", email: "", birthday: Date(), joinDate: Date().description, role: ProfileRole.nurse, isAdmin: false)
    }
    
    // Update the profile
    func updateProfile() async throws {
        isWorking = true

        do {
            print("updating profile: \(tempProfile.musterId)")

            try await profileRepository.updateProfile(profile: tempProfile)
            self.profile = tempProfile
            self.profile.musterId = ""
            self.isWorking = false
        } catch {
            self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
            self.isWorking = false
            throw error
        }
    }
    
    func updateOtherProfile(profile: Profile) async throws {
        isWorking = true
        
        do {
            print("About to update profile: \(profile.firstName)")
            try await profileRepository.updateProfile(profile: profile)
            self.isWorking = false
        } catch {
            self.isWorking = false
            throw error
        }
    }

    // Save the updated profile asynchronously
    private func saveProfile() {
        isWorking = true
    }

    @MainActor
    // Sign out the user asynchronously
    func signOut() {
        isWorking = true

        Task {
            do {
                try await profileRepository.signOut()
                self.isWorking = false
                self.loggedIn = false
                self.appState = AppState.splash
                
            } catch {
                self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                self.isWorking = false
            }
        }
    }

    // Reset profile data
    func reset() {
        profile = Profile()
        errorMessage = nil
    }
}
