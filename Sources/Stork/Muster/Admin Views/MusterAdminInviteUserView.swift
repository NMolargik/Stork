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
                                await musterViewModel.fetchSentInvitations(musterId: currentMuster.id)
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
                                    inviteUser(profile)
                                },
                                onCancelInvite: {
                                    cancelInvite(profile)
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
    private func inviteUser(_ profile: Profile) {
        Task {
            do {
                try await musterViewModel.inviteUserToMuster(userId: profile.id)
                // Refresh the invitations after sending invite
                await musterViewModel.fetchSentInvitations(musterId: musterViewModel.currentMuster!.id)
                print("Invited user: \(profile.firstName) \(profile.lastName)")
            } catch {
                errorMessage = "Failed to invite user. Please try again."
                print("Error inviting user: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Invitation (Placeholder)
    private func cancelInvite(_ profile: Profile) {
        // Placeholder function: Implement cancellation logic here
        Task {
            do {
                //try await musterViewModel.cancelInvitation(toUserId: profile.id)
                // Refresh the invitations after cancellation
                await musterViewModel.fetchSentInvitations(musterId: musterViewModel.currentMuster!.id)
                print("Cancelled invitation to user: \(profile.firstName) \(profile.lastName)")
            } catch {
                errorMessage = "Failed to cancel invitation. Please try again."
                print("Error cancelling invitation: \(error)")
            }
        }
    }
}
