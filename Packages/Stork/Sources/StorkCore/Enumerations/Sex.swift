//
//  Sex.swift
//  StorkCore
//
//  The recorded sex of a baby. Pure value type; the SwiftUI `Color` mapping lives
//  in `StorkDesignSystem`.
//

import Foundation

nonisolated public enum Sex: String, Codable, Hashable, CaseIterable, Identifiable, Sendable, CustomStringConvertible {
    case male
    case female
    case loss

    public var id: Sex { self }

    public var description: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .loss: "Loss"
        }
    }

    public var displayName: String {
        switch self {
        case .male: "Boy"
        case .female: "Girl"
        case .loss: "Loss"
        }
    }

    public var displayShort: String {
        switch self {
        case .male: "M"
        case .female: "F"
        case .loss: "Loss"
        }
    }
}
