//
//  MusterInvitationsView.swift
//  
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterInvitationsView: View {
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel

    var onDismiss: () -> Void
    var onRespond: (MusterInvite, Bool) -> Void
    
    var body: some View {
        NavigationStack {
//            List(musterViewModel.invites) { invite in
//                VStack(alignment: .leading) {
//                    Text(invite.senderName + " invited you to join " + invite.musterName)
//                        .font(.headline)
//                        .fontWeight(.bold)
//                    
//                    Text(invite.primaryHospitalName)
//                        .font(.subheadline)
//                        .foregroundStyle(.gray)
//                    
//                    Text(invite.message)
//                        .font(.body)
//                        .padding(.top, 2)
//                    
//                    if (musterViewModel.isWorking) {
//                        ProgressView()
//                            .tint(.indigo)
//                    } else if (invite.status == .accepted || invite.status == .declined) {
//                        Text(invite.status.stringValue)
//                            .foregroundStyle(.gray)
//                    } else {
//                        HStack {
//                            CustomButtonView(text: "Accept", width: 100, height: 40, color: Color.blue, isEnabled: .constant(true), onTapAction: {
//                                
//                                Task {
//                                    await musterViewModel.respondToInvite(invite: invite, accepted: true, profileId: profileViewModel.profile.id)
//                                    
//                                    profileViewModel.profile.musterId = invite.musterId
//                                    profileViewModel.updateProfile()
//                                    
//                                    await musterViewModel.loadCurrentMuster(profileId: profileViewModel.profile.id)
//                                    
//                                    musterViewModel.isWorking = false
//                                    onDismiss()
//                                }
//                            })
//                            
//                            CustomButtonView(text: "Decline", width: 100, height: 40, color: Color.red, isEnabled: .constant(true), onTapAction: {
//                                
//                                Task {
//                                    await musterViewModel.respondToInvite(invite: invite, accepted: false, profileId: profileViewModel.profile.id)
//                                    
//                                    musterViewModel.isWorking = false
//                                }
//                            })
//                            
//                            Spacer()
//                            
//                            Image(systemName: "envelope.fill")
//                                .foregroundStyle(.gray)
//                        }
//                        .padding(.top, 4)
//                    }
//                }
//                .padding(.vertical, 8)
//            }
//            .onAppear {
//                Task {
//                    await musterViewModel.fetchMyInvitations(profileId: profileViewModel.profile.id)
//                }
//            }
//            .navigationTitle("Your Invitations")
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Close") {
//                        onDismiss()
//                    }
//                    .foregroundStyle(.red)
//                }
//            }
        }
    }
}

#Preview {
    MusterInvitationsView(
        onDismiss: {},
        onRespond: { _, _ in }
    )
    .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
    .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
