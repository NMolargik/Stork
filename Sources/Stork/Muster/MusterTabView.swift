//
//  MusterTabView.swift
//
//
//  Created by Nick Molargik on 11/29/24.
//

import SwiftUI
import StorkModel

struct MusterTabView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var musterViewModel: MusterViewModel
    
    var body: some View {
        Group {
            if let muster = musterViewModel.currentMuster {
                // User is in a muster
                NavigationStack {
                    VStack {
                        // Show muster statistics or info
                        Text("Statistics for \(muster.name)")
                            .font(.title)
                            .padding()

                        // Placeholder for stats
                        Text("Muster Stats Go Here")
                            .padding()
                        
                        Spacer()
                        
                        // If user is admin, show admin controls
                        if musterViewModel.isUserAdmin(of: muster, profileId: profileViewModel.profile.id) {
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
                            
                            Button("Kick Member") {
                                musterViewModel.showKickMemberSheet = true
                            }
                            .padding(.top, 4)
                            
                            Button("Change Primary Color") {
                                musterViewModel.showChangeColorSheet = true
                            }
                            .padding(.top, 4)
                        }
                        
                        Spacer()
                        
                        // Leave muster button at the bottom
                        Button("Leave Muster") {
                            musterViewModel.showLeaveConfirmation = true
                        }
                        .padding(.bottom)
                    }
                    .navigationTitle(muster.name)
                    .toolbar {
                        // Potential additional toolbar items
                    }
                    .confirmationDialog(
                        "Are you sure you want to leave this muster?",
                        isPresented: $musterViewModel.showLeaveConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Leave", role: .destructive) {
                            Task {
                                await musterViewModel.leaveMuster(profileId: profileViewModel.profile.id)
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    // Admin sheets
                    .sheet(isPresented: $musterViewModel.showInviteUserSheet) {
                        MusterAdminInviteUserView { profile in
                            Task {
                                await musterViewModel.inviteUserToMuster(userId: profile.id)
                            }
                        }
                    }
                    .sheet(isPresented: $musterViewModel.showAssignAdminSheet) {
                        MusterAdminAssignAdminView { userId in
                            Task {
                                await musterViewModel.assignAdmin(userId: userId)
                            }
                        }
                    }
                    .sheet(isPresented: $musterViewModel.showKickMemberSheet) {
                        MusterAdminKickMemberView { userId in
                            Task {
                                await musterViewModel.kickMember(userId: userId)
                            }
                        }
                    }
                    .sheet(isPresented: $musterViewModel.showChangeColorSheet) {
                        MusterAdminChangeColorView { newColor in
                            Task {
                                await musterViewModel.changeMusterColor(newColor: newColor)
                            }
                        }
                    }
                }
            } else {
                // User is not in a muster
                MusterSplashView()
            }
        }
        .task {
            // Attempt to load user's current muster at start
            print("LOADING YOUR MUSTER")
            await musterViewModel.loadCurrentMuster(profileId: profileViewModel.profile.id)
        }
    }
}

#Preview {
    MusterTabView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
