//
//  PreferencesView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    @AppStorage(StorageKeys.useMetric) var useMetric: Bool = false

    var body: some View {
        Group {
            Toggle("Use Metric Units", isOn: $useMetric)
                .foregroundStyle(useDarkMode ? Color.white : Color.black)
                .tint(.green)

            #if !SKIP
            Toggle("Dark Mode", isOn: $useDarkMode)
                .foregroundStyle(useDarkMode ? Color.white : Color.black)
                .tint(.green)
            #endif
        }
    }
}

#Preview {
    PreferencesView()
}
