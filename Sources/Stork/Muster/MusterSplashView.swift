//
//  MusterSplashView.swift
//  
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterSplashView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""

    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        List {
            VStack {
                Image(systemName: "person.3")
                    .font(.system(size: 50))
                    .navigationTitle("Join A Muster")
                    .padding(.bottom)

                    
                Text("[ muhs-ter ] - noun\nA group of storks")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)

            if (musterViewModel.isWorking) {
                ProgressView()
            } else {
                
                Section {
                    VStack {
                        Text("Create a Muster or accept a pending invitation to an existing Muster to share statistics and gain insights with other nurses and doctors.")
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .padding(.bottom, 25)
                        
                        CustomButtonView(text: "Create New Muster", width: 300, height: 50, color: Color.indigo, icon: nil, isEnabled: true, onTapAction: {
                            musterViewModel.showCreateMusterSheet = true
                        })
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    triggerHaptic()
                    
                    Task {
                        do {
                            try await musterViewModel.fetchUserInvitations(profileId: profileViewModel.profile.id)
                            musterViewModel.showMusterInvitations = true
                        } catch {
                            errorMessage = error.localizedDescription
                            throw error
                        }
                    }
                }, label: {
                    Text("Invitations")
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                })
            }
        }
        .sheet(isPresented: $musterViewModel.showMusterInvitations) {
            MusterInvitationsView(
                showMusterInvitations: $musterViewModel.showMusterInvitations,
                onRespond: { invite, accepted in
                    Task {
                        do {
                            try await musterViewModel.respondToUserInvite(profile: profileViewModel.profile, invite: invite, accepted: accepted, profileViewModel: profileViewModel)
                            musterViewModel.showMusterInvitations = false
                        } catch {
                            errorMessage = error.localizedDescription
                            throw error
                        }
                    }
                }
            )
            .presentationDetents([.fraction(0.7)])
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $musterViewModel.showCreateMusterSheet) {
            MusterCreationView(showCreateMusterSheet: $musterViewModel.showCreateMusterSheet)
                .interactiveDismissDisabled(true)
            
        }
    }
}

#Preview {
    MusterSplashView()
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
