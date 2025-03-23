//
//  MissingHospitalHeaderView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

// MARK: - Header View
struct MissingHospitalHeaderView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    var body: some View {
        VStack {
            Text("Missing Hospital")
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("Sorry we are missing your hospital. Please provide its name and we will take it from there!")
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .multilineTextAlignment(.center)
                .font(.headline)
        }
    }
}



#Preview {
    MissingHospitalHeaderView()
        .environmentObject(AppStorageManager())
}
