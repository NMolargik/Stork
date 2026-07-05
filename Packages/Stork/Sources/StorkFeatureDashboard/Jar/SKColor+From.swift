//
//  SKColor+From.swift
//  StorkFeatureDashboard
//
//  Bridges a SwiftUI `Color` to a SpriteKit `SKColor` for the marble jar.
//

#if os(iOS)
import SwiftUI
import SpriteKit

extension SKColor {
    static func from(_ color: Color) -> SKColor { SKColor(color) }
}
#endif
