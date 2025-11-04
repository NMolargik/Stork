//
//  MainView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import SwiftUI
import WeatherKit

extension MainView {
    @Observable
    class ViewModel {
        // MARK: - UI State (moved from View)
        var appTab: AppTab = .home
        var showingEntrySheet: Bool = false
        var showingSettingsSheet: Bool = false
        var showingHospitalSheet: Bool = false
        var listPath = NavigationPath()
        var lastPushedDeliveryID: String? = nil
        var now: Date = Date()
        var drawOn: Bool = false

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

        func symbolName(for condition: WeatherCondition?) -> String {
            guard let c = condition else { return "cloud.sun.fill" }
            switch c {
            case .clear, .mostlyClear: return "sun.max.fill"
            case .partlyCloudy: return "cloud.sun.fill"
            case .cloudy: return "cloud.fill"
            case .rain, .heavyRain, .drizzle: return "cloud.rain.fill"
            case .thunderstorms: return "cloud.bolt.rain.fill"
            case .snow, .heavySnow: return "snowflake"
            case .foggy, .haze: return "cloud.fog.fill"
            default: return "cloud.sun.fill"
            }
        }

        func shortText(for condition: WeatherCondition?) -> String? {
            guard let c = condition else { return nil }
            switch c {
            case .clear, .mostlyClear: return "Clear"
            case .partlyCloudy: return "Partly Cloudy"
            case .cloudy: return "Cloudy"
            case .rain, .heavyRain, .drizzle: return "Rain"
            case .thunderstorms: return "Storms"
            case .snow, .heavySnow: return "Snow"
            case .foggy, .haze: return "Foggy"
            default: return nil
            }
        }
    }
}
