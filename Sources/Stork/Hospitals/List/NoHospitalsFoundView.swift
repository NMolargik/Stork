//
//  NoHospitalsFoundView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct NoHospitalsFoundView: View {
    var body: some View {
        Text("No hospitals found. Either Stork services are down, or you should change your search criteria.\n\nIf you feel your hospital is missing, report it using the button above.")
            .padding()
            .multilineTextAlignment(.center)
            .background(
                Color.white
                    .cornerRadius(20)
                    .shadow(radius: 2)
            )
            .padding()
    }
}

#Preview {
    NoHospitalsFoundView()
}
