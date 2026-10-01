//
//  Sex+Color.swift
//  StorkDesignSystem
//
//  Brand color mapping for a baby's recorded sex.
//

import SwiftUI
import StorkCore

public extension Sex {
    var color: Color {
        switch self {
        case .male: .storkBlue
        case .female: .storkPink
        case .loss: .storkPurple
        }
    }
}
