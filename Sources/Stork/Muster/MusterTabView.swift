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
                    //TODO: stacked profile view
                    Rectangle()
                        .cornerRadius(10)
                        .foregroundStyle(.blue)
                        .padding()
                    
                    MusterCarouselView()
                    
                    //TODO: user contribution distribution view
                    Rectangle()
                        .frame(height: 150)
                        .cornerRadius(10)
                        .foregroundStyle(.red)
                        .padding()
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
                        .presentationDetents([.medium])
                        .interactiveDismissDisabled(true)

                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            if musterViewModel.isUserAdmin(profile: profileViewModel.profile) {
                                
                                Button {
                                    musterViewModel.showInviteUserSheet = true
                                } label: {
                                    Label("Invite User", systemImage: "person.badge.plus")
                                }
                                
                                Button {
                                    musterViewModel.showAssignAdminSheet = true
                                } label: {
                                    Label("Assign Admin", systemImage: "person.badge.shield.exclamationmark.fill")
                                }
                            }
                            
                            Button {
                                leaveMuster()
                            } label: {
                                Label("Leave Muster", systemImage: "door.left.hand.open")
                            }
                            
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(.orange)
                                .fontWeight(.bold)
                        }
                    }
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
