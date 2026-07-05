//
//  DeliveryTag+Color.swift
//  StorkDesignSystem
//
//  Resolves a tag's stored `colorHex` to a SwiftUI `Color`, keeping the model (Core)
//  free of UI frameworks.
//

import SwiftUI
import StorkCore

public extension DeliveryTag {
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}
