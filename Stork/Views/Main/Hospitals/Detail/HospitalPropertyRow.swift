//
//  HospitalPropertyRow.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI

struct HospitalPropertyRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    HospitalPropertyRow(label: "Label", value: "Value", icon: "figure.child")
}
