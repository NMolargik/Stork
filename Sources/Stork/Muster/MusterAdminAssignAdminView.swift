//
//  MusterAdminAssignAdminView.swift
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI
import StorkModel

struct MusterAdminAssignAdminView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var musterViewModel: MusterViewModel
    @ObservedObject var profileViewModel: ProfileViewModel

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
                        .fontWeight(.bold)
                }
            }
        }
    }
}

#Preview {
    MusterAdminAssignAdminView(
        musterViewModel: MusterViewModel(musterRepository: MockMusterRepository()),
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager())
    )
}
