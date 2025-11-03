//
//  SKColor-From.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import SwiftUI
import SpriteKit

extension SKColor {
    static func from(_ color: Color) -> SKColor {
        // Convert SwiftUI Color to UIColor/SKColor safely
        return SKColor(color)
    }
}
