//
//  Tab.swift
//
//  Created by Nick Molargik on 11/28/24.
//

import Foundation

/// Represents the tabs available in the Stork app.
public enum Tab: String, Hashable, CaseIterable {
    case home
    case deliveries
    case hospitals
    case muster
    case settings

    /// The title displayed for the tab in the UI.
    var title: String {
        Tab.titles[self] ?? ""
    }

    var customIconName: String {
        switch self {
        case .home: return "house.tab"
        case .deliveries: return "figure.child.tab"
        case .hospitals: return "building.fill.tab"
        case .muster: return "person.3.fill.tab"
        case .settings: return "gear.tab"
        }
    }

    // MARK: - Private Mappings
    private static let titles: [Tab: String] = [
        .home: "Home",
        .deliveries: "Deliveries",
        .hospitals: "Hospitals",
        .muster: "Muster",
        .settings: "Settings"
    ]
}
