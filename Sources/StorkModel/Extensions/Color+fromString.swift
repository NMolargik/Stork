//
//  Color+fromString.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 12/26/24.
//

import SwiftUI

public extension Color {
    /// Initializes a Color from a string.
    /// - Parameter name: The name of the color (e.g., "red", "blue").
    /// - Returns: The corresponding Color if the name matches; otherwise, a default color.
    static func from(string: String) -> Color {
        switch string.lowercased() {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "green":
            return .green
        case "blue":
            return .blue
        case "purple":
            return .purple
        default:
            return .gray // Default color if no match found
        }
    }
}
