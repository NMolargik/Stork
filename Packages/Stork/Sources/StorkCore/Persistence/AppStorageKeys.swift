//
//  AppStorageKeys.swift
//  StorkCore
//
//  Central registry of `@AppStorage` / UserDefaults keys, so the literal strings live
//  in one place and are shared between the app and its view models.
//

import Foundation

nonisolated public enum AppStorageKeys {
    public static let isOnboardingComplete = "isOnboardingComplete"
    public static let useMetricUnits = "useMetricUnits"
    public static let useDayMonthYearDates = "useDayMonthYearDates"
    public static let selectedIconColor = "selectedIconColor"
    public static let dashboardCardOrder = "homeCardOrder"
    /// Comma-separated `BirthRole` raw values excluded from the headline total (empty = all count).
    public static let excludedBirthRoles = "excludedBirthRoles"
    public static let calendarHeatMapEnabled = "calendarHeatMapEnabled"
    /// Whether the shared Year Wrap image carries the gentle "Remembered: N" line. Off by default.
    public static let wrapShareIncludesRemembrance = "wrapShareIncludesRemembrance"
    /// The Wrap year whose dashboard invitation the user dismissed.
    public static let wrapPromptDismissedYear = "wrapPromptDismissedYear"

    /// Privacy lock (free for everyone): require Face ID / Touch ID / passcode to open Stork.
    public static let requireBiometricLock = "requireBiometricLock"
    /// Seconds in the background before the lock re-engages (`AppLockPolicy.timeoutOptions`).
    public static let lockTimeoutSeconds = "lockTimeoutSeconds"

    // Stork Pro entitlement cache (StoreManager). Cached so gating works offline and the
    // grandfather check doesn't re-query the App Store receipt every launch.
    public static let proPurchased = "StorkPro.isPurchased"
    public static let proGrandfathered = "StorkPro.isGrandfathered"
    public static let proGrandfatherChecked = "StorkPro.didCheckGrandfather"
    public static let proGrandfatherThankYouShown = "StorkPro.didShowGrandfatherThankYou"
}
