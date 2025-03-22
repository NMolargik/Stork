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
                .tint(.green)

            Toggle("Dark Mode", isOn: $appStorageManager.useDarkMode)
                .tint(.green)
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(AppStorageManager())
}
