//
//  MusterAdminInviteUserView.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterAdminInviteUserView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var searchEnabled: Bool = false
    
    @State private var profiles: [Profile] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    CustomTextfieldView(
                        text: $searchText,
                        hintText: "Search by last name",
                        icon: Image(systemName: "magnifyingglass"),
                        isSecure: false,
                        iconColor: Color.blue
                    )
                    
                    CustomButtonView(
                        text: "Search",
                        width: 80,
                        height: 55,
                        color: Color.indigo,
                        isEnabled: $searchEnabled,
                        onTapAction: {
                            withAnimation {
                                profileViewModel.isWorking = true
                                searchUsers()
                            }
                        }
                    )
                    .onChange(of: searchText) { text in
                        searchEnabled = text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
                    }
                    .onAppear {
                        searchEnabled = searchText.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
                        
                        Task {
                            if let currentMuster = musterViewModel.currentMuster {
                                do {
                                    try await musterViewModel.getMusterInvitations(muster: currentMuster)
                                    
                                } catch {
                                    errorMessage = error.localizedDescription
                                    throw error
                                }
                            }
                        }
                    }
                }
                .padding()
                
                // Profiles List
                if profileViewModel.isWorking {
                    ProgressView()
                        .tint(.indigo)
                        .padding()
                } else {
                    List {
                        ForEach(profiles, id: \.id) { profile in
                            ProfileRowView(
                                existingInvitations: $musterViewModel.invites,
                                profile: profile,
                                currentUser: profileViewModel.profile,
                                onInvite: {
                                    inviteUser(profile: profile)
                                },
                                onCancelInvite: { invite in
                                    cancelInvite(profile: profile, invite: invite)
                                }
                            )
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("Invite User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
    
    // MARK: - Search Users
    private func searchUsers() {
        Task {
            do {
                self.profiles = try await profileViewModel.profileRepository.listProfiles(
                    id: nil,
                    firstName: nil,
                    lastName: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: nil,
                    birthday: nil,
                    role: nil,
                    primaryHospital: nil,
                    joinDate: nil,
                    musterId: nil,
                    isAdmin: nil
                )
                
                print("Profiles found: \(self.profiles)")
                
                profileViewModel.isWorking = false
            } catch {
                errorMessage = "Failed to search for users. Please try again."
                profileViewModel.isWorking = false
            }
        }
    }
    
    // MARK: - Invite User
    private func inviteUser(profile: Profile) {
        Task {
            do {
                try await musterViewModel.inviteUserToMuster(profile: profile)
                print("Invited user: \(profile.firstName) \(profile.lastName)")
            } catch {
                errorMessage = error.localizedDescription
                throw error
            }
        }
    }
    
    // MARK: - Cancel Invitation (Placeholder)
    private func cancelInvite(profile: Profile, invite: MusterInvite) {
        // Placeholder function: Implement cancellation logic here
        Task {
            if musterViewModel.currentMuster != nil {
                do {
                    try await musterViewModel.respondToUserInvite(profile: profile, invite: invite, accepted: false)
                    print("Cancelled invitation to user: \(profile.firstName) \(profile.lastName)")
                } catch {
                    errorMessage = error.localizedDescription
                    throw error
                }
            }
        }
    }
}
