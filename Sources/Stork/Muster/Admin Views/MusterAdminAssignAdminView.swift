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
                        adminProfileIds: Set(musterViewModel.currentMuster?.administratorProfileIds ?? []),
                        onAssign: {
                            Task {
                                try await musterViewModel.assignAdmin(userId: profile.id)
                            }
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
}

#Preview {
    MusterAdminAssignAdminView()
        .environmentObject(MusterViewModel(musterRepository: MockMusterRepository()))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))
}
