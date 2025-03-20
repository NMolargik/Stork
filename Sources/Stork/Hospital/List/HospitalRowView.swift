//
//  HospitalRowView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import SwiftUI
import StorkModel

struct HospitalRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @Binding var selectionMode: Bool
    
    let hospital: Hospital
    
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                Text(hospital.facility_name)
                    .font(.headline)
                    .foregroundStyle(selectionMode ? Color("storkBlue") : (colorScheme == .dark ? .white : .black))
                
                if (hospital.citytown == "") {
                    Text("Unknown Location")
                        .font(.system(size: 12))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                } else {
                    Text("\(hospital.citytown), \(hospital.state)")
                        .font(.system(size: 12))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                }
                
                HStack {
                    Text("Deliveries: \(hospital.deliveryCount)")
                    
                    Text("Babies: \(hospital.babyCount)")

                }
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            
            }
            
            Spacer()
            
            if (profileViewModel.profile.primaryHospitalId == hospital.id) {
                Image("star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.yellow)
            }
        }
    }
}

#Preview {
    HospitalRowView(
        profileViewModel: ProfileViewModel(profileRepository: MockProfileRepository(), appStorageManager: AppStorageManager()),
        selectionMode: .constant(true),
        hospital: Hospital(id: "1234523423542342342342342342342", facility_name: "Parkview Hospital", address: "1116 South Hamsher Street", citytown: "Garrett", state: "IN", zip_code: "46738", countyparish: "Dekalb", telephone_number: "260-357-6625", hospital_type: "Normal Type", hospital_ownership: "Molargik", emergency_services: true, meets_criteria_for_birthing_friendly_designation: true, deliveryCount: 10, babyCount: 12)
    )
}
