//
//  MissingHospitalSheetView.swift
//
//
//  Created by Nick Molargik on 12/1/24.
//

import SwiftUI

// MARK: - Missing Hospital Sheet View
struct MissingHospitalSheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var hospitalName: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    var onSubmit: (String) async throws -> Void

    var body: some View {
        VStack(alignment: .center) {
            MissingHospitalHeaderView()
            
            CustomTextfieldView(
                text: $hospitalName,
                hintText: "Missing hospital name...",
                icon: Image("building"),
                isSecure: false,
                iconColor: Color("storkOrange")
            )
            .padding()

            if let errorMessage = errorMessage {
                ErrorMessageView(errorMessage: errorMessage)
            }

            if isSubmitting {
                ProgressView()
                    .tint(Color("storkOrange"))
                    .frame(height: 50)
            } else {
                MissingHospitalActionsView(
                    hospitalName: $hospitalName,
                    isSubmitting: $isSubmitting,
                    errorMessage: $errorMessage,
                    dismiss: dismiss,
                    onSubmit: onSubmit
                )
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    MissingHospitalSheetView { hospitalName in
        print("Submitted hospital: \(hospitalName)")
    }
}
