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
        case .male: String(localized: "Male", bundle: .module)
        case .female: String(localized: "Female", bundle: .module)
        case .loss: String(localized: "Loss", bundle: .module)
        }
    }

    public var displayName: String {
        switch self {
        case .male: String(localized: "Boy", bundle: .module)
        case .female: String(localized: "Girl", bundle: .module)
        case .loss: String(localized: "Loss", bundle: .module)
        }
    }

    public var displayShort: String {
        switch self {
        case .male: String(localized: "M", bundle: .module)
        case .female: String(localized: "F", bundle: .module)
        case .loss: String(localized: "Loss", bundle: .module)
        }
    }
}
