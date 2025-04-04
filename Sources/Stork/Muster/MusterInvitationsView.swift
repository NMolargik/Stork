//
//  MusterInvitationsView.swift
//  
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterInvitationsView: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false

    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    
    @Binding var showMusterInvitations: Bool
    
    var onRespond: (MusterInvite, Bool) -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if (musterViewModel.isWorking) {
                    ProgressView()
                        .tint(Color("storkIndigo"))
                        .frame(height: 50)
                } else if (musterViewModel.invites.count == 0) {
                    
                    VStack {
                        Image("exclamationmark.magnifyingglass", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.orange)
                            .frame(width: 50, height: 50)
                            .padding()
                        
                        Text("No invitations found. Ask a muster admin to send you an invitation!")
                            .foregroundStyle(useDarkMode ? Color.white : Color.black)
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .padding(.horizontal)

                    }
                    .padding()

                } else {
                    
                    ScrollView {
                        ForEach(musterViewModel.invites) { invite in
                            VStack(alignment: .leading) {
                                Text(invite.senderName + " invited you to " + invite.musterName)
                                    .font(.headline)
                                    .foregroundStyle(useDarkMode ? .white : .black)

                                HStack {
                                    CustomButtonView(text: "Accept", width: 100, height: 40, color: Color("storkBlue"), isEnabled: true, onTapAction: {
                                        
                                        Task {
                                            try await musterViewModel.respondToUserInvite(profile: profileViewModel.profile, invite: invite, accepted: true, profileViewModel: profileViewModel)
                                            
                                            print("Invite Muster ID: \(invite.musterId)")
                                            profileViewModel.tempProfile = profileViewModel.profile
                                            profileViewModel.tempProfile.musterId = invite.musterId
                                            try await profileViewModel.updateProfile()
                                            
                                            print("New profile musterID: \(profileViewModel.profile.musterId)")
                                            
                                            try await musterViewModel.loadCurrentMuster(profileViewModel: profileViewModel, deliveryViewModel: deliveryViewModel)
                                            
                                            musterViewModel.isWorking = false
                                            musterViewModel.invites.removeAll(where: { $0.musterId == invite.musterId })
                                            showMusterInvitations = false
                                            
                                            dismiss()
                                        }
                                    })
                                    
                                    CustomButtonView(text: "Decline", width: 100, height: 40, color: Color.red, isEnabled: true, onTapAction: {
                                        
                                        Task {
                                            try await musterViewModel.respondToUserInvite(profile: profileViewModel.profile, invite: invite, accepted: false, profileViewModel: profileViewModel)
                                                                                        
                                            musterViewModel.isWorking = false
                                            musterViewModel.invites.removeAll(where: { $0.musterId == invite.musterId })
                                        }
                                    })
                                }
                            }
                            .padding()
                            .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
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
                        withAnimation {
                            appStateManager.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .navigationTitle("Your Invitations")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticFeedback.trigger(style: .medium)
                        showMusterInvitations = false
                        dismiss()
                    }
                    .foregroundStyle(.red)
                    .bold()
                }
            }
        } 
    }
}

#Preview {
    MusterInvitationsView(
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository()),
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        showMusterInvitations: .constant(true),
        onRespond: { _, _ in }
    )
    .environmentObject(AppStateManager.shared)
}
