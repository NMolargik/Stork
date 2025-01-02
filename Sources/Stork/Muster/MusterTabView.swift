//
//  MusterTabView.swift
//
//
//  Created by Nick Molargik on 11/29/24.
//

import SwiftUI
import StorkModel

struct MusterTabView: View {
    @AppStorage("errorMessage") var errorMessage: String = ""

    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var deliveryViewModel: DeliveryViewModel
    @EnvironmentObject var hospitalViewModel: HospitalViewModel
    
    @State private var showingMusterInvitations: Bool = false
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            
            if let muster = musterViewModel.currentMuster {
                VStack {
                    // Show muster statistics or info
                    Text("Statistics for \(muster.name)")
                        .font(.title)
                        .padding()
                    
                    // Placeholder for stats
                    Text("Muster Stats Go Here")
                        .padding()
                    
                    Spacer()
                    
                    Text("Members")
                    
                    ForEach(musterViewModel.musterMembers, id: \.self) { member in
                        Text(member.firstName)
                    }
                    
                    // If user is admin, show admin controls
                    if musterViewModel.isUserAdmin(profile: profileViewModel.profile) {
                        Divider()
                        Text("Admin Controls")
                            .font(.headline)
                            .padding(.top)
                        
                        Button("Invite User") {
                            musterViewModel.showInviteUserSheet = true
                        }
                        .padding(.top, 4)
                        
                        Button("Assign Admin") {
                            musterViewModel.showAssignAdminSheet = true
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    Button("Leave Muster") {
                        musterViewModel.showLeaveConfirmation = true
                    }
                    .padding(.bottom)
                    
                    MusterCarouselView()
                        .background {
                            Color.blue
                        }
                    
                }
                .refreshable {
                    Task {
                        try await musterViewModel.loadCurrentMuster(profileViewModel: profileViewModel)
                    }
                }
                .navigationTitle(muster.name)
                .confirmationDialog(
                    "Are you sure you want to leave this muster?",
                    isPresented: $musterViewModel.showLeaveConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Leave", role: .destructive) {
                        
                        leaveMuster()
                    }
                    Button("Cancel", role: .cancel) {}
                }
                // Admin sheets
                .sheet(isPresented: $musterViewModel.showInviteUserSheet) {
                    MusterAdminInviteUserView()
                        .interactiveDismissDisabled(true)
                }
                .sheet(isPresented: $musterViewModel.showAssignAdminSheet) {
                    MusterAdminAssignAdminView()
                }
            } else {
                MusterSplashView()
            }
        }
    }
    
    private func triggerHaptic() {
        #if !SKIP
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    private func leaveMuster() {
        Task {
            musterViewModel.isWorking = true

            do {
                try await musterViewModel.leaveMuster(profileViewModel: profileViewModel)
                
                profileViewModel.tempProfile = profileViewModel.profile
                profileViewModel.tempProfile.musterId = ""
                
                try await profileViewModel.updateProfile()
            } catch {
                musterViewModel.isWorking = false
                errorMessage = error.localizedDescription
                throw error
            }
            
            musterViewModel.isWorking = false
        }
    }
}

#Preview {
    MusterTabView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
