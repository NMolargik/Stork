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
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits = false
    @State private var showAttribution = false

    var body: some View {
        Group {
            if manager.isFetching {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("Loading...").font(.subheadline).foregroundStyle(.secondary)
                }
                .accessibilityLabel("Loading...")
            } else if manager.error != nil {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").imageScale(.medium)
                    Text("Unavailable").font(.footnote).foregroundStyle(.secondary)
                        .onTapGesture { Task { await manager.refresh() } }
                }
                .accessibilityLabel("Weather unavailable")
            } else {
                HStack(spacing: 8) {
                    manager.condition?.weatherSymbolView().imageScale(.medium)
                    if let temp = manager.temperatureString(useMetric: useMetricUnits) {
                        Text(temp).font(.headline).bold().monospacedDigit()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { showAttribution = true }
                .popover(isPresented: $showAttribution, arrowEdge: .bottom) { AttributionPopover() }
                .task { await manager.refresh() }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current weather")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private struct AttributionPopover: View {
        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 4) { Image(systemName: "apple.logo"); Text("Weather") }.font(.headline)
                Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                    Text("Legal Attribution").font(.subheadline).foregroundStyle(.blue)
                }
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
}
#endif
