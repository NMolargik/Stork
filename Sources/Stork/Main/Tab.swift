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

    /// The SF Symbol name used for the tab's icon.
    var icon: String {
        Tab.icons[self] ?? "questionmark"
    }

    // MARK: - Private Mappings
    private static let titles: [Tab: String] = [
        .home: "Home",
        .deliveries: "Deliveries",
        .hospitals: "Hospitals",
        .muster: "Muster",
        .settings: "Settings"
    ]

    private static let icons: [Tab: String] = [
        .home: "house",
        .deliveries: "figure.child",
        .hospitals: "building",
        .muster: "person.3",
        .settings: "gear"
    ]
}
