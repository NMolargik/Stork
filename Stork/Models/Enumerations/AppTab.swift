//
//  AppTab.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Dashboard"
    case list = "Deliveries"
    case calendar = "Calendar"
    case settings = "Settings"

    var id: String { self.rawValue }

    func icon() -> Image {
        switch self {
        case .home:
            return Image(systemName: "circle.hexagongrid.fill")
        case .list:
            return Image(systemName: "list.bullet")
        case .calendar:
            return Image(systemName: "calendar")
        case .settings:
            return Image(systemName: "gearshape.2")
        }
    }

    func color() -> Color {
        switch self {
        case .home:
            return Color.storkPurple
        case .list:
            return Color.storkBlue
        case .calendar:
            return Color.storkPink
        case .settings:
            return Color.storkOrange
        }
    }
}
