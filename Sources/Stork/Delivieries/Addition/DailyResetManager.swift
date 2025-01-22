//
//  DailyResetManager.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI
import Combine

class DailyResetManager: ObservableObject {
    private var resetTimer: Timer?
    private let calendar = Calendar.current

    @AppStorage("currentDeliveryCount") private var currentDeliveryCount: Int = 0
    @AppStorage("lastResetDate") private var lastResetDate: Double = 0

    private let dailyLimit = 8

    init() {
        checkForDailyReset()
        scheduleMidnightReset()
    }

    deinit {
        resetTimer?.invalidate()
    }

    // MARK: - Reset Logic

    /// Ensures the count is reset if a new day has started.
    private func checkForDailyReset() {
        let now = Date()
        let lastReset = Date(timeIntervalSince1970: lastResetDate)

        if calendar.startOfDay(for: now) > calendar.startOfDay(for: lastReset) {
            resetDailyLimit()
        }
    }

    /// Schedules a reset at the next midnight using `Timer`.
    private func scheduleMidnightReset() {
        resetTimer?.invalidate()

        let now = Date()
        let midnight = calendar.startOfDay(for: now).addingTimeInterval(86400) // Next day's midnight
        let interval = midnight.timeIntervalSince(now)

        resetTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.resetDailyLimit()
            self?.scheduleMidnightReset() // Reschedule for the next day
        }
    }

    private func resetDailyLimit() {
        DispatchQueue.main.async {
            self.currentDeliveryCount = 0
            self.lastResetDate = Date().timeIntervalSince1970
            print("Daily limit reset at midnight.")
        }
    }

    // MARK: - Delivery Count Management

    func canSubmitDelivery() -> Bool {
        return currentDeliveryCount < dailyLimit
    }

    func incrementDeliveryCount() {
        DispatchQueue.main.async {
            if self.canSubmitDelivery() {
                self.currentDeliveryCount += 1
            }
        }
    }
}
