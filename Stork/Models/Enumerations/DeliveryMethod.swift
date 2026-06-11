//
//  DeliveryMethod.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

/// Represents the various methods of delivery available within the Stork application.
/// Nonisolated: a pure value type used from nonisolated contexts (App Intents
/// entity display, widget timelines) as well as the UI.
nonisolated enum DeliveryMethod: String, CaseIterable, Codable, Hashable, Sendable {
    case vaginal
    case cSection
    case vBac

    var description: String {
        switch self {
        case .vaginal:
            return "Vaginal"
        case .cSection:
            return "C-Section"
        case .vBac:
            return "VBAC"
        }
    }
    
    var displayName: String {
        switch self {
        case .vaginal: return "Vaginal"
        case .cSection: return "Cesarean"
        case .vBac: return "VBAC"
        }
    }
}
