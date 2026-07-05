//
//  Color+Hex.swift
//  StorkDesignSystem
//
//  Hex string ↔ SwiftUI `Color` conversion, used for user-customizable tag colors.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

nonisolated public extension Color {
    /// Parses a 6-digit "RRGGBB" (optionally "#"-prefixed) hex string.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgbValue) else { return nil }

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }

    /// The "RRGGBB" hex for this color, or `nil` where `UIColor` is unavailable.
    func toHex() -> String? {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
        #else
        return nil
        #endif
    }
}
