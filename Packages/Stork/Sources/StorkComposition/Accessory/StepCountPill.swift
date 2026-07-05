//
//  StepCountPill.swift
//  StorkComposition
//
//  Step-count display for the tab bar bottom accessory.
//

#if os(iOS) && canImport(HealthKit)
import SwiftUI
import StorkDesignSystem
import StorkServices

struct StepCountPill: View {
    let manager: HealthManager
    let onShowTrend: () -> Void

    var body: some View {
        Group {
            if !manager.isStepTrackingSupported {
                EmptyView()
            } else if manager.isAuthorized {
                HStack(spacing: 10) {
                    Image(systemName: "figure.walk").imageScale(.medium)
                    Text("\(manager.todayStepCount) steps today").font(.headline).bold().monospacedDigit()
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                .onTapGesture { Haptics.lightImpact(); onShowTrend() }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Today's steps")
                .accessibilityValue(Text("\(manager.todayStepCount)"))
                .accessibilityHint("Tap to view weekly step trend")
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk").imageScale(.medium).foregroundStyle(.storkPurple)
                    Text("Connect Health").font(.footnote).foregroundStyle(.secondary)
                }
                .task {
                    await manager.requestAuthorization()
                    manager.startObservingStepCount()
                }
                .accessibilityLabel("Connect Health to show pedometer")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
#endif
