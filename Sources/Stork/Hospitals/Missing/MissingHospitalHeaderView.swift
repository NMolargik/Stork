//
//  MissingHospitalHeaderView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

// MARK: - Header View
struct MissingHospitalHeaderView: View {
    var body: some View {
        VStack {
            Text("Missing Hospital")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Sorry we are missing your hospital. Please provide its name and we will take it from there!")
                .multilineTextAlignment(.center)
                .font(.headline)
        }
    }
}



#Preview {
    MissingHospitalHeaderView()
}
