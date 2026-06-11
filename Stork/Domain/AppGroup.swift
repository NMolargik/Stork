//
//  AppGroup.swift
//  Stork
//

import Foundation

/// Shared identifiers used across the app, widget, and watch targets.
enum AppGroup {
    static let id = "group.com.molargiksoftware.Stork"
}

/// Keys for values shared with extensions through the app group container.
/// The app writes these on every save so widgets have a fallback when
/// SwiftData is unavailable in the extension process.
enum SharedDefaultsKey {
    static let babiesThisWeekCount = "babiesThisWeekCount"
    static let careerTotalBabies = "careerTotalBabies"
    static let careerTotalDeliveries = "careerTotalDeliveries"
}

/// WidgetKit timeline kinds, shared so the app can request reloads by kind.
enum WidgetKind {
    static let deliveriesThisWeek = "DeliveriesThisWeekWidget"
}
