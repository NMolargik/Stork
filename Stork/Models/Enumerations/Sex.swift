//
//  Sex.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation
import SwiftUI

/// Represents the sex of a baby within the Stork application.
enum Sex: String, Codable, Hashable, CaseIterable, Identifiable, CustomStringConvertible {
    case male
    case female
    case loss

    public var id: Sex { self }

    public var description: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .loss:
            return "Loss"
        }
    }

    public var color: Color {
        switch self {
        case .male:
            return .storkBlue
        case .female:
            return .storkPink
        case .loss:
            return .storkPurple
        }
    }
    
    var displayName: String {
        switch self {
        case .male: return "Boy"
        case .female: return "Girl"
        case .loss: return "Loss"
        }
    }
    var displayShort: String {
        switch self {
        case .male: return "M"
        case .female: return "F"
        case .loss: return "Loss"
        }
    }
}
