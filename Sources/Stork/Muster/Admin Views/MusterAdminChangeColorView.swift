//
//  MusterAdminChangeColorView.swift
//
//
//  Created by Nick Molargik on 12/11/24.
//

import SwiftUI

struct MusterAdminChangeColorView: View {
    var onChangeColor: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var newColor = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("New Color Hex/Name", text: $newColor)
            }
            .navigationTitle("Change Primary Color")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Change") {
                        onChangeColor(newColor)
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
    MusterAdminChangeColorView(onChangeColor: { _ in })
}
