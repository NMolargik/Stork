//
//  NoHospitalsFoundView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct NoHospitalsFoundView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Image("exclamationmark.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundStyle(Color("storkOrange"))
                .shadow(radius: 2)
            
            Text("No hospitals found. Try changing your search criteria.")
                .multilineTextAlignment(.center)
                .frame(height: 70)
        }
        .padding()
        .backgroundCard(colorScheme: colorScheme)
    }
}

#Preview {
    NoHospitalsFoundView()
}
