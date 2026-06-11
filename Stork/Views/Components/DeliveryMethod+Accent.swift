//
//  DeliveryMethod+Accent.swift
//  Stork
//

import SwiftUI

/// The single source of truth for delivery-method accent colors, so the
/// dashboard, calendar, and detail views all speak the same color language.
/// MainActor because the generated asset-color symbols are MainActor-isolated.
extension DeliveryMethod {
    var accentColor: Color {
        switch self {
        case .vaginal: return .storkBlue
        case .cSection: return .storkOrange
        case .vBac: return .storkPurple
        }
    }
}
