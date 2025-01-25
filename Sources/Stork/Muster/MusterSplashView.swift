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
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person.3")
                    .font(.system(size: 50))
                    .navigationTitle("Join A Muster")                
                
                Text("[ muhs-ter ] - noun\nA group of storks")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .backgroundCard(colorScheme: colorScheme)
            .padding(8)
            
            Text("Create a Muster or accept a pending invitation to an existing Muster to share statistics and gain insights with other nurses and doctors.")
                .multilineTextAlignment(.center)
                .font(.body)
                .fontWeight(.semibold)
                .padding(20)
                .backgroundCard(colorScheme: colorScheme)
                
            Spacer()
            
            CustomButtonView(text: "Create A New Muster", width: 300, height: 50, color: Color.indigo, icon: Image(systemName: "plus"), isEnabled: true, onTapAction: {
                musterViewModel.showCreateMusterSheet = true
            })
            .padding(.bottom, 5)

            CustomButtonView(text: "View Your Invitations", width: 300, height: 50, color: Color.orange, icon: Image(systemName: "envelope.fill"), isEnabled: true, onTapAction: {
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
            })
            
            Spacer()
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
                .presentationDetents([.fraction(0.75)])
                .interactiveDismissDisabled(true)
        }
    }
}

#Preview {
    MusterSplashView()
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
