//
//  WeatherPill.swift
//  StorkComposition
//
//  Current-conditions display for the tab bar bottom accessory.
//

#if os(iOS)
import SwiftUI
import StorkCore
import StorkServices

struct WeatherPill: View {
    let manager: WeatherManager
    /// Signals a tap on the loaded pill. The attribution sheet is presented by the stable
    /// root (`MainView`), never from here — a sheet presented inside the tab-bar bottom
    /// accessory is torn down with the accessory on the next weather refresh and dismisses
    /// itself immediately.
    let onShowAttribution: () -> Void
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false

    var body: some View {
        Group {
            if manager.isFetching {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("Loading...", bundle: .module).font(.subheadline).foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Loading...", bundle: .module))
            } else if manager.error != nil {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").imageScale(.medium)
                    Text("Unavailable", bundle: .module).font(.footnote).foregroundStyle(.secondary)
                        .onTapGesture { Task { await manager.refresh() } }
                }
                .accessibilityLabel(Text("Weather unavailable", bundle: .module))
            } else {
                HStack(spacing: 8) {
                    manager.condition?.weatherSymbolView().imageScale(.medium)
                    if let temp = manager.temperatureString(useMetric: useMetricUnits) {
                        Text(temp).font(.headline).bold().monospacedDigit()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { onShowAttribution() }
                .task { await manager.refresh() }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Current weather", bundle: .module))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Centered modal for the WeatherKit legal attribution. Presented from `MainView`'s stable
/// root — see `WeatherPill.onShowAttribution`.
struct WeatherAttributionSheet: View {
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "apple.logo")
                    Text("Weather", bundle: .module)
                }
                .font(.title2.bold())

                Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                    Text("Legal Attribution", bundle: .module).font(.headline).foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { onClose() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(Text("Close", bundle: .module))
                }
            }
        }
        .presentationDetents([.medium])
    }
}
#endif
