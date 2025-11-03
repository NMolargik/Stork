//
//  HospitalDetailPropertyView.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import SwiftUI

struct HospitalDetailPropertyView: View {
    let hospital: Hospital
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HospitalPropertyRow(label: "Hospital Type", value: hospital.hospitalType.isEmpty ? "N/A" : hospital.hospitalType, icon: "building.columns")
            HospitalPropertyRow(label: "Ownership", value: hospital.hospitalOwnership.isEmpty ? "N/A" : hospital.hospitalOwnership, icon: "person.2")
            HospitalPropertyRow(label: "County/Parish", value: hospital.countyparish.isEmpty ? "N/A" : hospital.countyparish, icon: "map")
            Group {
                if hospital.telephoneNumber.isEmpty {
                    HospitalPropertyRow(label: "Telephone", value: "N/A", icon: "phone")
                } else {
                    Button {
                        let digits = hospital.telephoneNumber.filter { $0.isNumber }
                        if let url = URL(string: "tel://\(digits)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HospitalPropertyRow(label: "Telephone", value: hospital.telephoneNumber, icon: "phone")
                            .foregroundStyle(.storkBlue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Call \(hospital.telephoneNumber)")
                }
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .clipped()
    }
}

#Preview {
    HospitalDetailPropertyView(hospital: Hospital.sample())
}
