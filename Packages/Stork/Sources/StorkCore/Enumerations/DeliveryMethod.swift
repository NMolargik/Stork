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
        case .vaginal: String(localized: "Vaginal", bundle: .module)
        case .cSection: String(localized: "C-Section", bundle: .module)
        case .vBac: String(localized: "VBAC", bundle: .module)
        }
    }

    /// Full user-facing name.
    public var displayName: String {
        switch self {
        case .vaginal: String(localized: "Vaginal", bundle: .module)
        case .cSection: String(localized: "Cesarean", bundle: .module)
        case .vBac: String(localized: "VBAC", bundle: .module)
        }
    }
}
