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
        fetchCurrentProfile()
    }

    @MainActor
    // Fetch the current profile asynchronously
    func fetchCurrentProfile() {
        isWorking = true
        Task {
            do {
                let fetchedProfile = try await profileRepository.getCurrentProfile()
                self.profile = fetchedProfile
                self.isWorking = false
            } catch {
                self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                self.isWorking = false
                throw error
            }
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
    
    // Update the profile
    func updateProfile() async throws {
        isWorking = true
        
        Task {
            do {
                try await profileRepository.updateProfile(profile: tempProfile)
                self.profile = tempProfile
                self.isWorking = false
            } catch {
                self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                self.isWorking = false
                throw error
            }
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
        
        //TODO: broken
        Task {
            do {
                try await profileRepository.signOut()
                DispatchQueue.main.async {
                    self.isWorking = false
                    self.loggedIn = false
                    // Handle post-sign-out actions, e.g., navigate to splash screen
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    self.isWorking = false
                }
            }
        }
    }

    // Reset profile data
    func reset() {
        profile = Profile()
        errorMessage = nil
    }
}
