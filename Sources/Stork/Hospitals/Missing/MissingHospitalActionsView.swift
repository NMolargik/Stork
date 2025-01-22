//
//  MissingHospitalActionsView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct MissingHospitalActionsView: View {
    @Binding var hospitalName: String
    @Binding var isSubmitting: Bool
    @Binding var errorMessage: String?
    let dismiss: DismissAction
    let onSubmit: (String) async throws -> Void

    var body: some View {
        HStack {
            submitButton
            cancelButton
        }
    }

    private var submitButton: some View {
        CustomButtonView(
            text: "Submit",
            width: 150,
            height: 40,
            color: hospitalName.isEmpty || isSubmitting ? .gray : .indigo,
            isEnabled: !hospitalName.isEmpty && !isSubmitting,
            onTapAction: handleSubmit
        )
    }

    private var cancelButton: some View {
        CustomButtonView(
            text: "Cancel",
            width: 150,
            height: 40,
            color: .red,
            isEnabled: true,
            onTapAction: { dismiss() }
        )
    }

    private func handleSubmit() {
        Task {
            guard !isSubmitting else { return }  // Prevent multiple submissions
            isSubmitting = true
            errorMessage = nil
            
            do {
                try await onSubmit(hospitalName)
                dismiss()
            } catch {
                errorMessage = "Failed to add hospital: \(error.localizedDescription)"
            }
            
            isSubmitting = false
        }
    }
}
