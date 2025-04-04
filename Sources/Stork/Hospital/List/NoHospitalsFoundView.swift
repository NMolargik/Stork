//
//  NoHospitalsFoundView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct NoHospitalsFoundView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    
    var body: some View {
        VStack {
            Image("exclamationmark.magnifyingglass", bundle: .module)
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
        .backgroundCard(colorScheme: useDarkMode ? .dark : .light)
        .padding()

    }
}

#Preview {
    NoHospitalsFoundView()
}
