//
//  AppTab.swift
//  StorkCore
//
//  The top-level tabs of the single adaptive `TabView`. Raw values are stable
//  identifiers and must never be shown to users — use `localizedTitle`, which routes
//  through the string catalog. The SF Symbol name is exposed; views build the `Image`.
//

import Foundation

nonisolated public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard = "Dashboard"
    case list = "Deliveries"
    case calendar = "Calendar"
    case settings = "Settings"

    public var id: String { rawValue }

    public var localizedTitle: LocalizedStringResource {
        switch self {
        case .dashboard: LocalizedStringResource("Dashboard", bundle: .atURL(Bundle.module.bundleURL))
        case .list: LocalizedStringResource("Deliveries", bundle: .atURL(Bundle.module.bundleURL))
        case .calendar: LocalizedStringResource("Calendar", bundle: .atURL(Bundle.module.bundleURL))
        case .settings: LocalizedStringResource("Settings", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    public var systemImage: String {
        switch self {
        case .dashboard: "circle.hexagongrid.fill"
        case .list: "list.bullet"
        case .calendar: "calendar"
        case .settings: "gearshape.2"
        }
    }
}
