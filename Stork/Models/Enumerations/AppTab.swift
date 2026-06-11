//
//  AppTab.swift
//  Stork
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case list = "Deliveries"
    case calendar = "Calendar"
    case settings = "Settings"

    var id: String { self.rawValue }

    /// Localizable title — raw values are identifiers and must not be
    /// shown to users (they bypass the string catalog).
    var localizedTitle: LocalizedStringResource {
        switch self {
        case .dashboard: "Dashboard"
        case .list: "Deliveries"
        case .calendar: "Calendar"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "circle.hexagongrid.fill"
        case .list: "list.bullet"
        case .calendar: "calendar"
        case .settings: "gearshape.2"
        }
    }

    func icon() -> Image {
        Image(systemName: systemImage)
    }

    func color() -> Color {
        switch self {
        case .dashboard: .storkPurple
        case .list: .storkBlue
        case .calendar: .storkPink
        case .settings: .storkOrange
        }
    }
}
