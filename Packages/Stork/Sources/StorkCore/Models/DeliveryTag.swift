//
//  DeliveryTag.swift
//  StorkCore
//
//  A user-defined label for organizing and filtering deliveries. The color is stored
//  as a hex string here (pure domain); `StorkDesignSystem` adds the SwiftUI `Color`
//  conversion so Core stays free of UI frameworks.
//

import Foundation
import SwiftData

@Model
public final class DeliveryTag {
    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "007AFF" // Default blue
    public var deliveries: [Delivery]?

    public init(id: UUID = UUID(), name: String, colorHex: String = "007AFF") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    /// Preset tags offered when a user creates their first tags.
    public static let presets: [(name: String, colorHex: String)] = [
        ("Teaching Moment", "FF9500"),    // Orange
        ("Difficult", "FF3B30"),          // Red
        ("First Solo", "34C759"),         // Green
        ("Memorable", "AF52DE"),          // Purple
        ("Night Shift", "5856D6"),        // Indigo
        ("Weekend", "FF2D55"),            // Pink
        ("Holiday", "FFCC00"),            // Yellow
        ("Multiple Birth", "00C7BE"),     // Teal
        ("Preterm", "FF6482"),            // Coral
        ("VBAC Success", "30B0C7"),       // Cyan
    ]
}

#if DEBUG
public extension DeliveryTag {
    static var sample: DeliveryTag {
        DeliveryTag(name: "Teaching Moment", colorHex: "FF9500")
    }
}
#endif
