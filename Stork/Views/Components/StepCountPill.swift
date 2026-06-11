//
//  StepCountPill.swift
//  Stork
//

#if !os(visionOS)
import SwiftUI

/// Step count display for the tab bar bottom accessory. Taps open the
/// weekly trend sheet; when unauthorized it requests Health access.
struct StepCountPill: View {
    @Environment(HealthManager.self) private var healthManager

    let onShowTrend: () -> Void

    var body: some View {
        Group {
            if !healthManager.isStepTrackingSupported {
                // No pedometer in this environment (e.g. "Designed for iPad"
                // on Mac or Apple Vision Pro) — show nothing.
                EmptyView()
            } else if healthManager.isAuthorized {
                HStack(spacing: 10) {
                    Image(systemName: "figure.walk")
                        .imageScale(.medium)

                    Text("\(healthManager.todayStepCount) steps today")
                        .font(.headline)
                        .bold()
                        .monospacedDigit()

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.lightImpact()
                    onShowTrend()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Today's steps")
                .accessibilityValue(Text("\(healthManager.todayStepCount)"))
                .accessibilityHint("Tap to view weekly step trend")
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .imageScale(.medium)
                        .foregroundStyle(.storkPurple)
                    Text("Connect Health")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .task {
                    await healthManager.requestAuthorization()
                    healthManager.startObservingStepCount()
                }
                .accessibilityLabel("Connect Health to show pedometer")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    StepCountPill(onShowTrend: {})
        .environment(HealthManager())
}

#endif
