//
//  Tab.swift
//  
//
//  Created by Nick Molargik on 11/28/24.
//

import Foundation

public enum Tab : String, Hashable {
    case home, deliveries, hospitals, muster, settings
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .deliveries:
            return "Deliveries"
        case .hospitals:
            return "Hospitals"
        case .muster:
            return "Muster"
        case .settings:
            return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .home:
            return "house"
        case .deliveries:
            return "figure.child"
        case .hospitals:
            return "building"
        case .muster:
            return "person.3"
        case .settings:
            return "gear"
        }
    }
}
