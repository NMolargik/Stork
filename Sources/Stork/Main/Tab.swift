//
//  Tab.swift
//
//  Created by Nick Molargik on 11/28/24.
//

import Foundation

/// Represents the tabs available in the Stork app.
public enum Tab: String, Hashable {
    /// Home tab, showing user statistics and main information.
    case home
    
    /// Deliveries tab, for managing and recording baby deliveries.
    case deliveries
    
    /// Hospitals tab, to view and manage hospital details.
    case hospitals
    
    /// Muster tab, for collaborating with and viewing muster details.
    case muster
    
    /// Settings tab, for managing app settings and preferences.
    case settings

    /// The title displayed for the tab in the UI.
    var title: String {
        switch self {
        case .home: return "Home"
        case .deliveries: return "Deliveries"
        case .hospitals: return "Hospitals"
        case .muster: return "Muster"
        case .settings: return "Settings"

        }
    }

    /// The SF Symbol name used for the tab's icon.
    var icon: String {
        switch self {
        case .home: return "house"
        case .deliveries: return "figure.child"
        case .hospitals: return "building"
        case .muster: return "person.3"
        case .settings: return "gear"
        }
    }
}
