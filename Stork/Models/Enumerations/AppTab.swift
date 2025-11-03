//
//  AppTab.swift
//  Stork
//
//  Created by Nick Molargik on 10/3/25.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case list = "Deliveries"
    case hospitals = "Hospitals"
    case settings = "Settings"
    
    var id: String { self.rawValue }

    func icon() -> Image {
        switch self {
        case .home:
            return Image(systemName: "house.fill")
        case .list:
            return Image(systemName: "list.bullet")
        case .hospitals:
            return Image(systemName: "building.2.fill")
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
        case .hospitals:
            return Color.red
        case .settings:
            return Color.storkOrange
        }
    }
}
