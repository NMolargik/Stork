// HospitalRowView.swift
// Stork
//
// Created by Nick Molargik on 10/5/25.
//

import SwiftUI

struct HospitalRowView: View {
    let hospital: Hospital
    let isPrimary: Bool
    
    var body: some View {
        HStack {
            if isPrimary {
                Rectangle()
                    .frame(width: 4, height: 40)
                    .cornerRadius(20)
                    .foregroundStyle(.yellow.gradient)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(hospital.facilityName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                HStack {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .frame(width: 15)
                            .foregroundStyle(.storkBlue)

                        Text("\(hospital.citytown), \(hospital.state)")
                    }
                    .font(.body)
                    
                    Spacer()
                    
                    if hospital.meetsCriteriaForBirthingFriendlyDesignation {
                        Image(systemName: "figure.child")
                            .foregroundStyle(.storkPurple.gradient)
                            .frame(width: 20)
                    }
                    
                    if hospital.emergencyServices {
                        Image(systemName: "cross.fill")
                            .foregroundStyle(.red.gradient)
                            .frame(width: 20)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hospital: \(hospital.facilityName), \(hospital.citytown), \(hospital.state)\(", Zip Code \(hospital.zipCode)")\(hospital.meetsCriteriaForBirthingFriendlyDesignation ? ", Birthing Friendly" : "")")
    }
}

#Preview {
    HospitalRowView(
        hospital: Hospital(
            facilityName: "Sample Hospital",
            citytown: "Seattle",
            state: "WA",
            zipCode: "98101",
            meetsCriteriaForBirthingFriendlyDesignation: true
        ),
        isPrimary: true
    )
    .padding()
    .background(Color(uiColor: .systemBackground))
}
