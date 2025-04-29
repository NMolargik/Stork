//
//  DailyResetManager.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SkipFoundation
import SwiftUI

class DailyResetUtility: ObservableObject {
    @AppStorage("currentDailyDeliveryCount") var currentDeliveryCount: Int = 0
    @AppStorage("lastResetDate") var lastResetDate: Double = 0
    
    private var resetTimer: Timer?
    private let calendar = Calendar.current
    private let dailyLimit = 8

    init() {
        checkForDailyReset()
        scheduleMidnightReset()
    }

    deinit {
        resetTimer?.invalidate()
    }

    private func checkForDailyReset() {
        let now = Date()
        let lastReset = Date(timeIntervalSince1970: lastResetDate)
        if calendar.startOfDay(for: now) > calendar.startOfDay(for: lastReset) {
            Task { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.resetDailyLimit()
                }
            }
        }
    }

    private func scheduleMidnightReset() {
        resetTimer?.invalidate()
        let now = Date()
        let midnight = calendar.startOfDay(for: now).addingTimeInterval(86400)
        let interval = midnight.timeIntervalSince(now)

        resetTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.resetDailyLimit()
                    self.scheduleMidnightReset()
                }
            }
        }
    }

    @MainActor
    private func resetDailyLimit() {
        currentDeliveryCount = 0
        lastResetDate = Date().timeIntervalSince1970
        print("Daily limit reset at midnight.")
    }

    func canSubmitDelivery() -> Bool {
        return currentDeliveryCount < dailyLimit
    }

    @MainActor
    func incrementDeliveryCount() {
        if canSubmitDelivery() {
            currentDeliveryCount += 1
        }
    }
}
