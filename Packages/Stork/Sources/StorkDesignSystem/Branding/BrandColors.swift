//
//  BrandColors.swift
//  StorkDesignSystem
//
//  The Stork brand palette, defined in code (display-P3) so the colors resolve identically
//  in the app, widgets, watch, and host `swift build` without relying on asset-catalog
//  symbol generation. Declared on `ShapeStyle where Self == Color` (mirroring how Xcode's
//  generated color symbols and SwiftUI's built-ins work) so `.storkBlue` is usable both as
//  a `Color` value and directly in `.foregroundStyle`/`.fill`/`.tint`.
//

import SwiftUI

public extension ShapeStyle where Self == Color {
    /// Primary brand blue — boys, the info accent, and the app tint.
    static var storkBlue: Color { Color(.displayP3, red: 78 / 255, green: 171 / 255, blue: 255 / 255) }

    /// Brand pink — girls.
    static var storkPink: Color { Color(.displayP3, red: 233 / 255, green: 113 / 255, blue: 255 / 255) }

    /// Brand purple — loss and VBAC.
    static var storkPurple: Color { Color(.displayP3, red: 96 / 255, green: 54 / 255, blue: 255 / 255) }

    /// Brand orange — cesarean.
    static var storkOrange: Color { Color(.displayP3, red: 232 / 255, green: 103 / 255, blue: 43 / 255) }
}
