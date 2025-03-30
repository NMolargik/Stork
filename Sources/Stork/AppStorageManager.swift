//
//  AppStorageManager.swift
//
//
//  Created by Nick Molargik on 3/14/25.
//

import SkipFoundation
import SwiftUI

public struct StorageKeys {
    static let isOnboardingComplete = "isOnboardingComplete"
    static let useDarkMode = "useDarkMode"
    static let useMetric = "useMetric"
    static let dailyDeliveryCount = "dailyDeliveryCount"
    static let lastResetDate = "lastResetDate"
}

public class AppStorageManager: ObservableObject {
    @AppStorage(StorageKeys.isOnboardingComplete) var isOnboardingComplete: Bool = false
    @AppStorage(StorageKeys.useDarkMode) var useDarkMode: Bool = false
    @AppStorage(StorageKeys.useMetric) var useMetric: Bool = false
    @AppStorage(StorageKeys.dailyDeliveryCount) var dailyDeliveryCount: Int = 0
    @AppStorage(StorageKeys.lastResetDate) var lastResetDate: Double = 0
}
