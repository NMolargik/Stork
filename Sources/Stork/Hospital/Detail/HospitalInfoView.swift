//
//  HospitalInfoView.swift
//
//
//  Created by Nick Molargik on 3/17/25.
//

import SwiftUI
import StorkModel

struct HospitalInfoView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    let hospital: Hospital

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !hospital.citytown.isEmpty {
                InfoRowView(icon: Image("pin.fill", bundle: .module), text: "\(hospital.address) \(hospital.citytown), \(hospital.state) \(hospital.zip_code) - \(hospital.countyparish)", iconColor: Color.red)
            }
            
            if !hospital.telephone_number.isEmpty {
                InfoRowView(icon: Image("phone.fill", bundle: .module), text: hospital.telephone_number, iconColor: Color.green)
            }
            
            InfoRowView(
                icon: Image("info.circle.fill", bundle: .module),
                text: hospital.hospital_type == "MISSING" ? "Info coming soon!" : hospital.hospital_type,
                iconColor: Color.blue
            )
            
            if hospital.meets_criteria_for_birthing_friendly_designation {
                InfoRowView(icon: Image("figure.child", bundle: .module), text: "Birthing Center", iconColor: Color("storkIndigo"))
            }
            
            if hospital.emergency_services {
                InfoRowView(icon: Image("cross.fill", bundle: .module), text: "Emergency Services", iconColor: Color.red)
            }
            
            InfoRowView(
                icon: Image("figure.child", bundle: .module),
                text: "\(hospital.deliveryCount) deliver\(hospital.deliveryCount == 1 ? "y" : "ies"), \(hospital.babyCount) bab\(hospital.babyCount == 1 ? "y" : "ies")",
                iconColor: Color("storkBlue")
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .padding(.leading, 5)
        .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
        .padding(.horizontal)
    }
}

#Preview {
    HospitalInfoView(hospital: Hospital.sampleHospital())
}
