//
//  MusterAdminKickMemberView.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI

struct MusterAdminKickMemberView: View {
    var onKick: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var userId = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("User ID", text: $userId)
            }
            .navigationTitle("Kick Member")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kick") {
                        onKick(userId)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    MusterAdminKickMemberView(onKick: { _ in })
}
