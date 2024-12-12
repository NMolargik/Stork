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

    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var searchEnabled: Bool = false
    
    @State private var profiles: [Profile] = []
    
    var onInvite: (Profile) -> Void
    
    var body: some View {
        NavigationStack() {
            Group {
                HStack {
                    CustomTextfieldView(text: $searchText, hintText: "Search by last name", icon: Image(systemName: "magnifyingglass"), isSecure: false, iconColor: Color.blue)
                    
                    CustomButtonView(text: "Search", width: 80, height: 40, color: Color.indigo, isEnabled: $searchEnabled, onTapAction: {
                        withAnimation {
                            profileViewModel.isWorking = true
                            searchUsers()
                        }
                    })
                    .onChange(of: searchText) { text in
                        searchEnabled = text.count > 0
                    }
                    .onAppear {
                        searchEnabled = searchText.count > 0
                    }
                    
                }
                
                List {
                    //TODO: filter out yourself
                    //TODO: make profile row view
                        //TODO: indicate if user is already in a muster
                    //TODO: add Invite button if they're not in a muster

                }
                
                //TODO: add a progress / status / result message
                
            }
            .navigationTitle("Invite User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.red)
                }
            } 
        }
    }
    
    private func searchUsers() {
        Task {
            do {
                self.profiles = try await profileViewModel.profileRepository.listProfiles(id: nil, firstName: nil, lastName: searchText, email: nil, birthday: nil, role: nil, primaryHospital: nil, joinDate: nil, musterId: nil, isAdmin: nil)
                
                print(self.profiles)
                
                profileViewModel.isWorking = false
            } catch {
                errorMessage = "Failed to search for users. Try again."
                profileViewModel.isWorking = false
            }
        }
    }
}
#Preview {
    MusterAdminInviteUserView(onInvite: { _ in })
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
