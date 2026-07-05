//
//  DeliveryMethod.swift
//  StorkCore
//
//  The method of a delivery. A pure value type used from nonisolated contexts
//  (App Intents entity display, widget timelines) as well as the UI, so it is
//  marked `nonisolated`. The accent color lives in `StorkDesignSystem`.
//

import Foundation

nonisolated public enum DeliveryMethod: String, CaseIterable, Codable, Hashable, Sendable {
    case vaginal
    case cSection
    case vBac

    /// Short user-facing label.
    public var description: String {
        switch self {
        case .vaginal: "Vaginal"
        case .cSection: "C-Section"
        case .vBac: "VBAC"
        }
    }

    /// Full user-facing name.
    public var displayName: String {
        switch self {
        case .vaginal: "Vaginal"
        case .cSection: "Cesarean"
        case .vBac: "VBAC"
        }
    }
}
