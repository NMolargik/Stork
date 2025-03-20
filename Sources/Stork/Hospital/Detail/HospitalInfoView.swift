//
//  HospitalInfoView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct HospitalInfoView: View {
    @Environment(\.colorScheme) var colorScheme

    let hospital: Hospital

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !hospital.citytown.isEmpty {
                InfoRowView(icon: Image(systemName: "pin.fill"), text: "\(hospital.address) \(hospital.citytown), \(hospital.state) \(hospital.zip_code) - \(hospital.countyparish)", iconColor: Color.red)
            }
            
            if !hospital.telephone_number.isEmpty {
                InfoRowView(icon: Image(systemName: "phone.fill"), text: hospital.telephone_number, iconColor: Color.green)
            }
            
            InfoRowView(
                icon: Image(systemName: "info.square.fill"),
                text: hospital.hospital_type == "MISSING" ? "Info coming soon!" : hospital.hospital_type,
                iconColor: .blue
            )
            
            if hospital.meets_criteria_for_birthing_friendly_designation {
                InfoRowView(icon: Image(systemName: "figure.child"), text: "Birthing Center", iconColor: Color("storkIndigo"))
            }
            
            if hospital.emergency_services {
                InfoRowView(icon: Image(systemName: "cross.fill"), text: "Emergency Services", iconColor: Color.red)
            }
            
            InfoRowView(
                icon: Image(systemName: "figure.child"),
                text: "\(hospital.deliveryCount) deliver\(hospital.deliveryCount == 1 ? "y" : "ies"), \(hospital.babyCount) bab\(hospital.babyCount == 1 ? "y" : "ies")",
                iconColor: Color("storkBlue")
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .padding(.leading, 5)
        .backgroundCard(colorScheme: colorScheme)
        .padding(.horizontal)
    }
}

#Preview {
    HospitalInfoView(hospital: Hospital.sampleHospital())
}
