//
//  MusterInvitationsView.swift
//  
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterInvitationsView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""
    
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var showMusterInvitations: Bool
    
    var onRespond: (MusterInvite, Bool) -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if (musterViewModel.isWorking) {
                    ProgressView()
                        .tint(.indigo)
                } else if (musterViewModel.invites.count == 0) {
                    
                    VStack {
                        Image(systemName: "exclamationmark.magnifyingglass")
                            .font(.largeTitle)
                            .padding()
                        
                        Text("No invitations found. Ask a muster admin to send you an invitation!")
                            .multilineTextAlignment(.center)
                            .font(.title3)

                    }
                    .padding()

                } else {
                    
                    ScrollView {
                        ForEach(musterViewModel.invites) { invite in
                            VStack(alignment: .leading) {
                                Text(invite.senderName + " invited you to join " + invite.musterName)
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                
                                HStack {
                                    CustomButtonView(text: "Accept", width: 100, height: 40, color: Color.blue, isEnabled: .constant(true), onTapAction: {
                                        
                                        Task {
                                            try await musterViewModel.respondToUserInvite(profile: profileViewModel.profile, invite: invite, accepted: true, profileViewModel: profileViewModel)
                                            
                                            print("Invite Muster ID: \(invite.musterId)")
                                            profileViewModel.tempProfile = profileViewModel.profile
                                            profileViewModel.tempProfile.musterId = invite.musterId
                                            try await profileViewModel.updateProfile()
                                            
                                            print("New profile musterID: \(profileViewModel.profile.musterId)")
                                            
                                            try await musterViewModel.loadCurrentMuster(profileViewModel: profileViewModel)
                                            
                                            musterViewModel.isWorking = false
                                            musterViewModel.invites.removeAll(where: { $0.musterId == invite.musterId })
                                            showMusterInvitations = false
                                            
                                            dismiss()
                                        }
                                    })
                                    
                                    CustomButtonView(text: "Decline", width: 100, height: 40, color: Color.red, isEnabled: .constant(true), onTapAction: {
                                        
                                        Task {
                                            try await musterViewModel.respondToUserInvite(profile: profileViewModel.profile, invite: invite, accepted: false, profileViewModel: profileViewModel)
                                                                                        
                                            musterViewModel.isWorking = false
                                            musterViewModel.invites.removeAll(where: { $0.musterId == invite.musterId })
                                        }
                                    })
                                }
                            }
                            .padding()
                            .background {
                                Color.white
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                            }
                            .padding(5)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        try await musterViewModel.fetchUserInvitations(profileId: profileViewModel.profile.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .navigationTitle("Your Invitations")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showMusterInvitations = false
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
        } 
    }
}

#Preview {
    MusterInvitationsView(
        showMusterInvitations: .constant(true),
        onRespond: { _, _ in }
    )
    .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
    .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
