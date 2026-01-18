//
//  WatchContentView.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

struct WatchContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Delivery.date, order: .reverse) private var allDeliveries: [Delivery]

    @State private var healthManager = WatchHealthManager()
    @State private var selectedTab: WatchTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "chart.bar.fill", value: .today) {
                TodayStatsView(deliveries: allDeliveries, healthManager: healthManager)
            }

            Tab("Add", systemImage: "plus.circle.fill", value: .add) {
                QuickEntryView()
            }

            Tab("Steps", systemImage: "figure.walk", value: .steps) {
                StepCountView(healthManager: healthManager)
            }
        }
        .task {
            await healthManager.requestAuthorization()
            healthManager.startObservingStepCount()
        }
    }
}

enum WatchTab {
    case today
    case add
    case steps
}

#Preview {
    WatchContentView()
}
