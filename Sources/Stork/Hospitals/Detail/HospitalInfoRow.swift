//
//  HospitalInfoRow.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct HospitalInfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)

            Text(text)
                .foregroundStyle(.black)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    HospitalInfoRow(icon: "figure.child", text: "Child Info", color: Color.indigo)
}
