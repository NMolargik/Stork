//
//  ProFeature.swift
//  StorkCore
//
//  The catalog of what Stork Pro unlocks. Logging deliveries, basic stats, the marble jar,
//  the calendar, the Watch app, basic Home Screen widgets, Spotlight, and Siri are free
//  forever and never appear here — data is never locked behind the purchase.
//

import Foundation

nonisolated public enum ProFeature: String, CaseIterable, Identifiable, Sendable {
    case milestoneShareCards
    case pdfExport
    case csvExport
    case insightCards
    case calendarHeatMap
    case alternateAppIcons
    case weatherAtDelivery
    case lockScreenWidgets
    case interactiveWidgets

    public var id: String { rawValue }

    /// Short feature name for paywall bullet lists and lock badges.
    public var displayName: String {
        switch self {
        case .milestoneShareCards: String(localized: "Career milestone share cards", bundle: .module)
        case .pdfExport: String(localized: "PDF reports", bundle: .module)
        case .csvExport: String(localized: "CSV export", bundle: .module)
        case .insightCards: String(localized: "Insight cards", bundle: .module)
        case .calendarHeatMap: String(localized: "Calendar heat map", bundle: .module)
        case .alternateAppIcons: String(localized: "Alternate app icons", bundle: .module)
        case .weatherAtDelivery: String(localized: "Weather at delivery", bundle: .module)
        case .lockScreenWidgets: String(localized: "Lock Screen widgets", bundle: .module)
        case .interactiveWidgets: String(localized: "Interactive widgets", bundle: .module)
        }
    }

    public var systemImage: String {
        switch self {
        case .milestoneShareCards: "star.square.on.square.fill"
        case .pdfExport: "doc.richtext.fill"
        case .csvExport: "tablecells.fill"
        case .insightCards: "chart.line.uptrend.xyaxis"
        case .calendarHeatMap: "calendar.badge.clock"
        case .alternateAppIcons: "app.badge.fill"
        case .weatherAtDelivery: "cloud.sun.fill"
        case .lockScreenWidgets: "lock.iphone"
        case .interactiveWidgets: "rectangle.3.group.fill"
        }
    }
}

/// The App Store product that unlocks every `ProFeature`. One non-consumable, Family
/// Sharing enabled; the literal lives here so the store, the StoreKit configuration file,
/// and tests agree.
nonisolated public enum StorkProProduct {
    public static let id = "com.nickmolargik.stork.pro.lifetime"
}

public extension DashboardCard {
    /// Insight cards (trends and records) are Pro; the basic count cards stay free.
    var requiresPro: Bool {
        switch self {
        case .deliveryMethod, .epiduralNicu, .babyCount, .sexDistribution, .roleBreakdown: false
        case .babyMeasurements, .timeOfDay, .dayOfWeek, .yearOverYear, .personalBests: true
        }
    }
}
