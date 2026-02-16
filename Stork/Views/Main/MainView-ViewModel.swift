//
//  MainView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import SwiftUI

extension MainView {
    @Observable
    class ViewModel {
        // MARK: - UI State (moved from View)
        var appTab: AppTab = .dashboard
        var showingEntrySheet: Bool = false
        var showingSettingsSheet: Bool = false
        var showingCalendarSheet: Bool = false
        var showingReorderSheet: Bool = false
        var showingStepTrendSheet: Bool = false
        var listPath = NavigationPath()
        var lastPushedDeliveryID: String? = nil
        var now: Date = Date()

        // MARK: - Actions (moved from View)
        func handleAddTapped() {
            showingEntrySheet = true
        }

        func updateDelivery(delivery: Delivery, reviewScene: UIWindowScene?, deliveryManager: DeliveryManager) {
            // If the delivery already exists (has babies array or is present in manager), treat as update is handled by caller elsewhere; otherwise create.
            if deliveryManager.deliveries.contains(where: { $0.id == delivery.id }) {
                // Do nothing here; updates are handled at the call site that passes an existing model and uses deliveryManager.update
                return
            } else {
                deliveryManager.create(delivery: delivery, reviewScene: reviewScene)
            }
            showingEntrySheet = false
        }

        // MARK: - Helpers (moved from View)
        func durationString(since start: Date, now: Date) -> String {
            let elapsed = max(0, Int(now.timeIntervalSince(start)))
            let hours = elapsed / 3600
            let minutes = (elapsed % 3600) / 60
            let seconds = elapsed % 60
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
    }
}
