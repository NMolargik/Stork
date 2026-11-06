//
//  DeliveryDateRule.swift
//  StorkCore
//
//  When a delivery may be dated. Nurses asked to back-date entries to any past shift, so
//  there is no lower bound; the only rule is "not in the future". The weather snapshot is
//  a *current* reading, so it is offered only when the delivery is recent enough for the
//  conditions outside to still describe it.
//

import Foundation

nonisolated public enum DeliveryDateRule {

    /// How far back a delivery can still take a live weather snapshot.
    public static let weatherSnapshotWindow: TimeInterval = 24 * 60 * 60

    /// A delivery may be dated any time up to and including `now`.
    public static func isAllowed(_ date: Date, now: Date = .now) -> Bool {
        date <= now
    }

    /// Pulls a future date back to `now`; past dates are returned untouched.
    public static func clamped(_ date: Date, now: Date = .now) -> Date {
        min(date, now)
    }

    /// Whether current conditions are a fair stand-in for the weather at this delivery.
    public static func allowsWeatherSnapshot(_ date: Date, now: Date = .now) -> Bool {
        isAllowed(date, now: now) && now.timeIntervalSince(date) <= weatherSnapshotWindow
    }
}
