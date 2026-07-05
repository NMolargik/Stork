//
//  AppGroup.swift
//  StorkCore
//
//  Shared identifiers across the app, widget, and watch targets, plus the keys the app
//  writes to the app-group container on every save so widgets have a SwiftData-free
//  fallback.
//

import Foundation

nonisolated public enum AppGroup {
    public static let id = "group.com.molargiksoftware.Stork"
}

/// Keys for values shared with extensions through the app-group container.
nonisolated public enum SharedDefaultsKey {
    public static let babiesThisWeekCount = "babiesThisWeekCount"
    public static let careerTotalBabies = "careerTotalBabies"
    public static let careerTotalDeliveries = "careerTotalDeliveries"
}

/// WidgetKit timeline kinds, shared so the app can request reloads by kind.
nonisolated public enum WidgetKind {
    public static let deliveriesThisWeek = "DeliveriesThisWeekWidget"
}
