//
//  MusterSplashView.swift
//  
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterSplashView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var appStorageManager: AppStorageManager

    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var deliveryViewModel: DeliveryViewModel
    @ObservedObject var hospitalViewModel: HospitalViewModel
    
    var body: some View {
        VStack {
            HStack {
                Image("person.3", bundle: .module)
                    .resizable()
                    .foregroundStyle(Color("storkIndigo"))
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .navigationTitle("Join A Muster")
                
                Text("[ muhs-ter ] - noun\nA group of storks")
                    .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)
            .padding(8)
            
            Text("Create a Muster or accept a pending invitation to an existing Muster to share statistics and gain insights with other nurses and doctors.")
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .multilineTextAlignment(.center)
                .font(.body)
                .fontWeight(.semibold)
                .padding(20)
                .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)
                
            Spacer()
            
            CustomButtonView(text: "Create A New Muster", width: 300, height: 50, color: Color("storkIndigo"), icon: nil, isEnabled: true, onTapAction: {
                musterViewModel.showCreateMusterSheet = true
            })
            .padding(.bottom, 5)

            CustomButtonView(text: "View Your Invitations", width: 300, height: 50, color: Color("storkOrange"), icon: nil, isEnabled: true, onTapAction: {
                HapticFeedback.trigger(style: .medium)
                
                Task {
                    do {
                        try await musterViewModel.fetchUserInvitations(profileId: profileViewModel.profile.id)
                        musterViewModel.showMusterInvitations = true
                    } catch {
                        withAnimation {
                            appStateManager.errorMessage = error.localizedDescription
                        }
                        throw error
                    }
                }
            })
            
            if (musterViewModel.isWorking && profileViewModel.profile.musterId != "") {
                Text("Loading Your Muster...")
                    .padding(.top)
                    .fontWeight(.bold)
                    .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                ProgressView()
                    .tint(Color("storkIndigo"))
            }
            
            Spacer()
        }
        .sheet(isPresented: $musterViewModel.showMusterInvitations) {
            MusterInvitationsView(
                musterViewModel: musterViewModel,
                profileViewModel: profileViewModel,
                deliveryViewModel: deliveryViewModel,
                showMusterInvitations: $musterViewModel.showMusterInvitations,
                onRespond: { invite, accepted in
                    Task {
                        do {
                            try await musterViewModel.respondToUserInvite(profile: profileViewModel.profile, invite: invite, accepted: accepted, profileViewModel: profileViewModel)
                            musterViewModel.showMusterInvitations = false
                        } catch {
                            withAnimation {
                                appStateManager.errorMessage = error.localizedDescription
                            }
                            throw error
                        }
                    }
                }
            )
            .presentationDetents([.fraction(0.7)])
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $musterViewModel.showCreateMusterSheet) {
            MusterCreationView(
                musterViewModel: musterViewModel,
                profileViewModel: profileViewModel,
                hospitalViewModel: hospitalViewModel,
                showCreateMusterSheet: $musterViewModel.showCreateMusterSheet
            )
                .presentationDetents([.fraction(0.75)])
                .interactiveDismissDisabled(true)
        }
    }
}

#Preview {
    MusterSplashView(
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        deliveryViewModel: DeliveryViewModel(deliveryRepository: MockDeliveryRepository()),
        hospitalViewModel: HospitalViewModel(hospitalRepository: MockHospitalRepository(), locationProvider: MockLocationProvider())
    )
    .environmentObject(AppStateManager.shared)
    .environmentObject(AppStorageManager())
        
}
