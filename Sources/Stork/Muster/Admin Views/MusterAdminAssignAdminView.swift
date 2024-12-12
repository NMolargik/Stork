//
//  MusterAdminAssignAdminView.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI

struct MusterAdminAssignAdminView: View {
    var onAssign: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var userId = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("User ID", text: $userId)
            }
            .navigationTitle("Assign Admin")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Assign") {
                        onAssign(userId)
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
    MusterAdminAssignAdminView(onAssign: { _ in })
}
