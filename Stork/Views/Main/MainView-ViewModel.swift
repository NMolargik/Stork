//
//  MainView-ViewModel.swift
//  Stork
//

import SwiftUI

extension MainView {
    @Observable
    final class ViewModel {
        // MARK: - UI State
        var appTab: AppTab = .dashboard
        var showingEntrySheet: Bool = false
        var showingReorderSheet: Bool = false
        var showingStepTrendSheet: Bool = false
        var listPath = NavigationPath()
        var lastPushedDeliveryID: String? = nil

        // MARK: - Actions

        func handleAddTapped() {
            showingEntrySheet = true
        }

        func handle(deepLink: DeepLink) {
            switch deepLink {
            case .newDelivery:
                showingEntrySheet = true
            case .dashboard:
                appTab = .dashboard
            case .deliveries, .weeklyDeliveries:
                appTab = .list
            case .delivery(let id):
                appTab = .list
                listPath.append(id)
            case .calendar:
                appTab = .calendar
            case .settings:
                appTab = .settings
            }
        }

        func saveNewDelivery(delivery: Delivery, reviewScene: UIWindowScene?, deliveryManager: DeliveryManager) {
            // Existing deliveries are updated by their own edit flow.
            if !deliveryManager.deliveries.contains(where: { $0.id == delivery.id }) {
                deliveryManager.create(delivery: delivery, reviewScene: reviewScene)
                // Teach Siri/Apple Intelligence about manual logs (Siri-initiated
                // logs are recorded by the system automatically).
                LogDeliveryIntent.donate(reflecting: delivery)
            }
            showingEntrySheet = false
        }
    }
}
