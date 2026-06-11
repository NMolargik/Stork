//
//  WeatherPill.swift
//  Stork
//

import SwiftUI

/// Current-conditions display for the tab bar bottom accessory, with
/// Apple Weather attribution shown in a popover on tap.
struct WeatherPill: View {
    @Environment(WeatherManager.self) private var weatherManager

    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    @State private var showAttribution: Bool = false

    var body: some View {
        Group {
            if weatherManager.isFetching {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Loading...")
            } else if weatherManager.error != nil {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .imageScale(.medium)
                    Text("Unavailable")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            Task {
                                await weatherManager.refresh()
                            }
                        }
                }
                .accessibilityLabel("Weather unavailable")
            } else {
                HStack(spacing: 8) {
                    weatherManager.condition?.weatherSymbolView()
                        .imageScale(.medium)

                    if let temp = weatherManager.temperatureString(useMetric: useMetricUnits) {
                        Text(temp)
                            .font(.headline)
                            .bold()
                            .monospacedDigit()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.lightImpact()
                    showAttribution = true
                }
                .popover(isPresented: $showAttribution, arrowEdge: .bottom) {
                    attributionPopover
                }
                .task {
                    await weatherManager.refresh()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current weather")
                .accessibilityHint("Tap to view weather attribution")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var attributionPopover: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "apple.logo")
                Text("Weather")
            }
            .font(.headline)

            Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                Text("Legal Attribution")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    WeatherPill()
        .environment(WeatherManager())
}
