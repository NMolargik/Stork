//
//  MusterSplashView.swift
//  
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterSplashView: View {
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        NavigationStack {
            
            //TODO: replace with muster icons
            Image(systemName: "person.3")
                .font(.system(size: 50))
                .navigationTitle("Join A Muster")
            
            List {
                Section {
                    HStack {
                        Spacer()
                        
                        Text("[ muhs-ter ] - noun\nA group of storks")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        
                        Text("Create a Muster or accept a pending invitation to an existing Muster to share statistics and gain insights with other nurses and doctors.")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                        
                        Spacer()
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        musterViewModel.showCreateMusterSheet = true
                    }, label: {
                        Text("Create New Muster")
                            .fontWeight(.bold)
                    })
                }
            }
            
            HStack {
                Spacer()
                
                CustomButtonView(text: "View Invitations", width: 200, height: 50, color: Color.indigo, icon: Image(systemName: "envelope.fill"), isEnabled: .constant(true), onTapAction: {
                    Task {
                        await musterViewModel.fetchMyInvitations(profileId: profileViewModel.profile.id)
                        musterViewModel.showInvitationsFullScreen = true
                    }
                })
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $musterViewModel.showInvitationsFullScreen) {
            MusterInvitationsView(
                onDismiss: { musterViewModel.showInvitationsFullScreen = false },
                onRespond: { invite, accepted in
                    Task {
                        await musterViewModel.respondToInvite(invite: invite, accepted: accepted, profileId: profileViewModel.profile.id)
                        await musterViewModel.fetchMyInvitations(profileId: profileViewModel.profile.id)
                    }
                }
            )
        }
        .sheet(isPresented: $musterViewModel.showCreateMusterSheet) {
            MusterCreationView { newMuster in
                Task {
                   try await musterViewModel.createMuster(profileId: profileViewModel.profile.id)
                }
            }
        }
    }
}

#Preview {
    MusterSplashView()
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
