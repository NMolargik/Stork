//
//  PreferencesView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/22/25.
//

import SwiftUI

struct PreferencesView: View {
    @Binding var useMetric: Bool
    @Binding var useDarkMode: Bool

    var body: some View {
        Section(header: Text("Preferences")) {
            Toggle("Use Metric Units", isOn: $useMetric)
                .tint(.green)

            Toggle("Dark Mode", isOn: $useDarkMode)
                .tint(.green)
        }
    }
}

#Preview {
    PreferencesView(useMetric: .constant(false), useDarkMode: .constant(false))
}
