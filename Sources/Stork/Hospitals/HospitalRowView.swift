//
//  HospitalRowView.swift
//
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation
import SwiftUI
import StorkModel

struct HospitalRowView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    let hospital: Hospital
    
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                Text(hospital.facility_name)
                    .font(.headline)
                
                Text("\(hospital.citytown), \(hospital.state)")
                    .font(.system(size: 12))
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                
                HStack {
                    Text("Deliveries: \(hospital.deliveryCount)")
                    
                    Text("Babies: \(hospital.babyCount)")

                }
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            
            }
            
            Spacer()
            
            if (profileViewModel.profile.primaryHospitalId == hospital.id) {
                Image(systemName: "star.fill")
                    .frame(width: 15)
                    .foregroundStyle(.yellow)
            }
        }
    }
}

#Preview {
    HospitalRowView(hospital: Hospital(id: "1234523423542342342342342342342", facility_name: "Parkview Hospital", address: "1116 South Hamsher Street", citytown: "Garrett", state: "IN", zip_code: "46738", countyparish: "Dekalb", telephone_number: "260-357-6625", hospital_type: "Normal Type", hospital_ownership: "Molargik", emergency_services: true, meets_criteria_for_birthing_friendly_designation: true, deliveryCount: 10, babyCount: 12))
        .environmentObject(ProfileViewModel(profileRepository: MockProfileRepository()))

}
