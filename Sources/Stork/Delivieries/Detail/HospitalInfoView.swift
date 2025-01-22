//
//  HospitalInfoView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct HospitalInfoView: View {
    let hospitalName: String

    var body: some View {
        InfoRowView(
            icon: Image(systemName: "building.fill"),
            text: hospitalName,
            iconColor: .orange
        )
    }
}

#Preview {
    HospitalInfoView(hospitalName: "Parkview Regional Medical Center")
}
