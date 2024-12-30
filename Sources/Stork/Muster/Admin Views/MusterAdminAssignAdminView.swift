//
//  MusterAdminAssignAdminView.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterAdminAssignAdminView: View {
    @EnvironmentObject var musterViewModel: MusterViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(musterViewModel.musterMembers, id: \.id) { profile in
                    ProfileAssignmentRowView(
                        profile: profile,
                        onAssign: {
                            assignUser(profile: profile)
                        }
                    )
                }
            }
            .navigationTitle("Assign Admin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // Update the profile locally in musterMembers
    private func updateProfileLocally(profileId: String) {
        if let index = musterViewModel.musterMembers.firstIndex(where: { $0.id == profileId }) {
            musterViewModel.musterMembers[index].isAdmin = true
        }
    }
    
    private func assignUser(profile: Profile) {
        Task {
            var tempProfile = profile
            tempProfile.isAdmin = true
            
            try await musterViewModel.assignAdmin(userId: tempProfile.id)
            updateProfileLocally(profileId: tempProfile.id)
            
            try await profileViewModel.updateProfileAdminStatus(profile: tempProfile)
        }
    }
}

#Preview {
    MusterAdminAssignAdminView()
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
