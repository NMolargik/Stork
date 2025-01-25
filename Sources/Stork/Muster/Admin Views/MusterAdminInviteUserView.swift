//
//  MusterAdminInviteUserView.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterAdminInviteUserView: View {
    @AppStorage("errorMessage") private var errorMessage: String = ""
    
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchEnabled = false
    @State private var profiles: [Profile] = []
    @State private var searchPerformed = false
    
    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                    .padding(.horizontal)

                if profiles.isEmpty && !profileViewModel.isWorking && searchPerformed {
                    Spacer()
                    
                    VStack {
                        Image("person.crop.badge.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.red)
                            .padding()
                        
                        Text("No users found with that last name")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                    }
                    
                    Spacer()
                } else if profileViewModel.isWorking {
                    Spacer()
                    
                    ProgressView()
                        .tint(Color("storkOrange"))
                        .frame(height: 50)
                    
                    Spacer()
                } else {
                    profilesListView
                }
            }
            .navigationTitle("Invite User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.red)
                        .fontWeight(.bold)
                }
            }
            .onAppear {
                refreshInvites()
                updateSearchEnabled()
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            CustomTextfieldView(
                text: $searchText,
                hintText: "Search by last name",
                icon: Image("magnifyingglass"),
                isSecure: false,
                iconColor: Color("storkBlue")
            )
            
            CustomButtonView(
                text: "Search",
                width: 80,
                height: 55,
                color: Color("storkIndigo"),
                isEnabled: searchEnabled,
                onTapAction: { withAnimation { searchUsers() } }
            )
        }
        .onChange(of: searchText) { _ in updateSearchEnabled() }
    }

    // MARK: - Profiles List View
    private var profilesListView: some View {
        ScrollView {
            LazyVStack {
                ForEach(profiles, id: \.id) { profile in
                    ProfileRowView(
                        existingInvitations: $musterViewModel.invites,
                        profile: profile,
                        currentUser: profileViewModel.profile,
                        onInvite: { inviteUser(profile: profile) }
                    )
                    .padding(.vertical, 5)
                    .padding(.horizontal)
                }
            }
        }
        .refreshable { searchUsers() }
        .padding(.top)
    }

    // MARK: - Search Users
    private func searchUsers() {
        guard !profileViewModel.isWorking else { return }
        
        profileViewModel.isWorking = true
        searchPerformed = true

        Task {
            do {
                profiles = try await profileViewModel.listProfiles(
                    id: nil,
                    firstName: nil,
                    lastName: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: nil,
                    birthday: nil,
                    role: nil,
                    primaryHospital: nil,
                    joinDate: nil,
                    musterId: nil
                )
                print("Profiles found: \(profiles)")
            } catch {
                errorMessage = "Failed to search for users. Please try again."
            }
            profileViewModel.isWorking = false
        }
    }

    // MARK: - Refresh Invitations
    private func refreshInvites() {
        Task {
            guard let muster = musterViewModel.currentMuster else { return }
            do {
                try await musterViewModel.getMusterInvitations(muster: muster)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Invite User
    private func inviteUser(profile: Profile) {
        Task {
            do {
                print("Inviting user: \(profile.firstName) \(profile.lastName)")
                try await musterViewModel.inviteUserToMuster(profile: profile, currentUser: profileViewModel.profile)
                refreshInvites()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Helper to Update Search Enabled State
    private func updateSearchEnabled() {
        searchEnabled = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
