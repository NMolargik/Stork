//
//  WatchContentView.swift
//  StorkWatch Watch App
//
//  The watch's three tabs. Deliveries flow through `WatchDeliveryModel` (use-cases), and
//  the change stream keeps them current when entries arrive from the phone via CloudKit.
//

import SwiftUI
import StorkCore
import StorkServices

struct WatchContentView: View {
    private let session: WatchSession
    @State private var model: WatchDeliveryModel
    @State private var selectedTab: WatchTab = .today

    init(session: WatchSession) {
        self.session = session
        _model = State(initialValue: WatchDeliveryModel(
            loadDeliveries: session.loadDeliveries,
            logDelivery: session.logDelivery
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "chart.bar.fill", value: .today) {
                TodayStatsView(deliveries: model.deliveries, healthManager: session.healthManager)
            }

            Tab("Add", systemImage: "plus.circle.fill", value: .add) {
                QuickEntryView(model: model)
            }

            Tab("Steps", systemImage: "figure.walk", value: .steps) {
                StepCountView(healthManager: session.healthManager)
            }
        }
        .task {
            await session.healthManager.requestAuthorization()
            session.healthManager.startObservingStepCount()
        }
        .task {
            // Local saves and CloudKit imports from the phone land on one stream.
            model.load()
            for await _ in session.observeDeliveryChanges() {
                model.load()
            }
        }
    }
}

enum WatchTab {
    case today
    case add
    case steps
}
