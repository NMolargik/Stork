//
//  HospitalDetailHeaderView.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import SwiftUI

struct HospitalDetailHeaderView: View {
    let hospital: Hospital
    
    var body: some View {
        VStack(spacing: 8) {
            Text(hospital.facilityName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.primary)
            
            Text("\(hospital.address), \n\(hospital.citytown), \(hospital.state) \(hospital.zipCode)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 12) {
                if hospital.meetsCriteriaForBirthingFriendlyDesignation {
                    Label("Birthing Friendly", systemImage: "figure.child")
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .foregroundStyle(.white)
                        .background(.storkPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
                
                if hospital.emergencyServices {
                    Label("Emergency Services", systemImage: "cross.circle.fill")
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .foregroundStyle(.white)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    HospitalDetailHeaderView(hospital: Hospital.sample())
}
