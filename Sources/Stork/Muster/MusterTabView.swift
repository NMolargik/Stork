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
                    .confirmationDialog(
                        "Are you sure you want to leave this muster?",
                        isPresented: $musterViewModel.showLeaveConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Leave", role: .destructive) {
                            Task {
                                do {
                                    try await musterViewModel.leaveMuster(profileId: profileViewModel.profile.id)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    throw error
                                }
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    // Admin sheets
                    .sheet(isPresented: $musterViewModel.showInviteUserSheet) {
                        MusterAdminInviteUserView()
                        #if !SKIP
                            .interactiveDismissDisabled(true)
                        #endif
                    }
                    .sheet(isPresented: $musterViewModel.showAssignAdminSheet) {
                        MusterAdminAssignAdminView { userId in
                            Task {
                                do {
                                    try await musterViewModel.assignAdmin(userId: userId)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    throw error
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $musterViewModel.showKickMemberSheet) {
                        MusterAdminKickMemberView { userId in
                            Task {
                                do {
                                    try await musterViewModel.kickMember(userId: userId)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    throw error
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $musterViewModel.showChangeColorSheet) {
                        MusterAdminChangeColorView { newColor in
                            Task {
                                do {
                                    try await musterViewModel.changeMusterColor(newColor: newColor)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    throw error
                                }
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
            guard profileViewModel.profile.musterId != "" else {
                return print("User is not in a muster")
            }
            
            print("Loading user's muster")
            
            Task {
                do {
                    try await musterViewModel.loadCurrentMuster(profile: profileViewModel.profile)
                } catch {
                    errorMessage = error.localizedDescription
                    throw error
                }
            }
        }
    }
}

#Preview {
    MusterTabView()
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
}
