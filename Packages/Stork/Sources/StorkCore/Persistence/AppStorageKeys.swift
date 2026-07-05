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
}
