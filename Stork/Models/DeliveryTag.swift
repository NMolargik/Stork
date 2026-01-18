//
//  DeliveryTag.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation
import SwiftData
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Represents a custom tag/label for deliveries.
/// Tags help organize and filter deliveries by memorable categories.
@Model
final class DeliveryTag {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "007AFF" // Default blue
    var deliveries: [Delivery]?

    init(id: UUID = UUID(), name: String, colorHex: String = "007AFF") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    /// Preset tags for common use cases
    static let presets: [(name: String, colorHex: String)] = [
        ("Teaching Moment", "FF9500"),    // Orange
        ("Difficult", "FF3B30"),           // Red
        ("First Solo", "34C759"),          // Green
        ("Memorable", "AF52DE"),           // Purple
        ("Night Shift", "5856D6"),         // Indigo
        ("Weekend", "FF2D55"),             // Pink
        ("Holiday", "FFCC00"),             // Yellow
        ("Multiple Birth", "00C7BE"),      // Teal
        ("Preterm", "FF6482"),             // Coral
        ("VBAC Success", "30B0C7")         // Cyan
    ]

    static var sample: DeliveryTag {
        DeliveryTag(name: "Teaching Moment", colorHex: "FF9500")
    }
}

// MARK: - Color Hex Extension

extension Color {
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

    func toHex() -> String? {
        #if canImport(UIKit)
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
        #else
        // watchOS fallback - return nil as we don't have UIColor
        return nil
        #endif
    }
}
