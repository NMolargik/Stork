//
//  DailyResetManager.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/30/24.
//

import SwiftUI
import Combine

class DailyResetManager: ObservableObject {
    private var timer: Timer?
    private var currentDate: Date = Date()
    private var dailyLimit = 8  // or store this in a global config
    
    @Published var currentDeliveryCount: Int = 0
    
    init() {
        // On launch, check if we need to reset immediately
        resetCountIfNeeded()
        // Then schedule the next midnight reset
        scheduleMidnightReset()
    }
    
    deinit {
        // In some designs, you might NOT invalidate here if the manager is truly app-wide.
        // But typically, if the entire app is closing, there's no need to keep the timer alive anyway.
        timer?.invalidate()
    }
    
    /// If the date changed, reset the daily limit.
    private func resetCountIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(currentDate, inSameDayAs: Date()) {
            currentDeliveryCount = 0
            currentDate = Date()
        }
    }
    
    /// Sets up a timer that fires at midnight (12:01 AM) and resets the count.
    private func scheduleMidnightReset() {
        timer?.invalidate()
        
        let now = Date()
        let calendar = Calendar.current
        
        // Extract the components for today
        let comps = calendar.dateComponents([.year, .month, .day], from: now)
        
        // Make a date at 00:01
        var resetComps = comps
        resetComps.hour = 0
        resetComps.minute = 1
        resetComps.second = 0
        
        guard let resetDate = calendar.date(from: resetComps) else { return }
        
        // If resetDate is in the past for today, move to tomorrow
        let adjustedResetDate = (resetDate > now)
          ? resetDate
          : calendar.date(byAdding: .day, value: 1, to: resetDate)!
        
        let interval = adjustedResetDate.timeIntervalSince(now)
        
        // Schedule the timer to fire once at midnight
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.resetDailyLimit()
            self.scheduleMidnightReset() // schedule again for the next day
        }
    }
    
    private func resetDailyLimit() {
        currentDeliveryCount = 0
        currentDate = Date()
        print("Daily limit has been reset at midnight.")
    }
    
    /// Example method that checks the daily limit
    func canSubmitDelivery() -> Bool {
        return currentDeliveryCount < dailyLimit
    }
    
    /// If user submits a delivery, increment
    func incrementDeliveryCount() {
        currentDeliveryCount += 1
    }
}
