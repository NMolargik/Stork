//
//  MissingHospitalSheetView.swift
//  
//
//  Created by Nick Molargik on 12/1/24.
//

import SwiftUI

struct MissingHospitalSheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hospitalName: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    var onSubmit: (String) async throws -> Void

    var body: some View {
        VStack(alignment: .center) {
            Text("Missing Hospital")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Sorry we are missing your hospital. Please provide its name and we will take it from there!")
                .multilineTextAlignment(.center)
                .font(.headline)
            
            CustomTextfieldView(text: $hospitalName, hintText: "Missing hospital name...", icon: Image(systemName: "building"), isSecure: false, iconColor: Color.orange)
                .padding()

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            }

            Button(action: {
                Task {
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
            }) {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hospitalName.isEmpty ? Color.gray : Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(hospitalName.isEmpty || isSubmitting)
            .padding()

            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(.red)
            }
        }
    }
}
