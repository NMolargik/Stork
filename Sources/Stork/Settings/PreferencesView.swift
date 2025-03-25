//
//  PreferencesView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager

    var body: some View {
        Section(header: Text("Preferences")) {
            Toggle("Use Metric Units", isOn: $appStorageManager.useMetric)
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .tint(.green)

            #if !SKIP
            Toggle("Dark Mode", isOn: $appStorageManager.useDarkMode)
                .foregroundStyle(appStorageManager.useDarkMode ? Color.white : Color.black)
                .tint(.green)
            #endif
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppStorageManager())
}
