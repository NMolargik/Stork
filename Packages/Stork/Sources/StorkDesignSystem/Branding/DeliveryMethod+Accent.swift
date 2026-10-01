//
//  DeliveryMethod+Accent.swift
//  StorkDesignSystem
//
//  The single source of truth for delivery-method accent colors, so the dashboard,
//  calendar, and detail views all speak the same color language.
//

import SwiftUI
import StorkCore

public extension DeliveryMethod {
    var accentColor: Color {
        switch self {
        case .vaginal: .storkBlue
        case .cSection: .storkOrange
        case .vBac: .storkPurple
        }
    }
}
