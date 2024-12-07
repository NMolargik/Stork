//
//  ProfileViewModel.swift
//
//
//  Created by Nick Molargik on 11/8/24.
//

import Foundation
import SwiftUI
import StorkModel

public class ProfileViewModel: ObservableObject {
    @AppStorage("appState") var appState: AppState = .register

    // MARK: - Published Properties
    @Published public var profile: Profile = Profile(thisIsTemporary: true)
    @Published var tempProfile: Profile = Profile(thisIsTemporary: true)
    @Published var dateRangeText: String = "06/07/1998 - 07/07/1998"
    @Published var errorMessage: String?
    @Published var selectedImageURL: URL?
        
    // MARK: - Dependencies
    var profileRepository: ProfileRepositoryInterface

    // MARK: - Initializer
    public init(profileRepository: ProfileRepositoryInterface) {
        self.profileRepository = profileRepository
    }

    // MARK: - Profile Image Loading Logic
    private func fetchImageData(from url: String) async throws -> Data {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    public func updateProfile() {
        self.profile.firstName = tempProfile.firstName
        self.profile.lastName = tempProfile.lastName
        self.profile.birthday = tempProfile.birthday
        self.profile.role = tempProfile.role
        
        Task {
            try await profileRepository.updateProfile(profile)
        }
    }
    
    public func signOut() {
        Task {
            self.reset()
            await self.profileRepository.signOut()
            print("Signed Out")
            appState = .splash
        }
    }
    
    public func reset() {
        self.dateRangeText = ""
        self.errorMessage = ""
        self.selectedImageURL = nil
        self.profile = Profile(thisIsTemporary: true)
    }
}
