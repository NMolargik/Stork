//
//  Double+toRadians.swift
//
//  Created by Nick Molargik on 11/30/24.
//

import Foundation

/// A `Double` extension that provides utility methods for angle conversions.
extension Double {
    
    // MARK: - Computed Properties
    
    /// Converts an angle from degrees to radians.
    ///
    /// - Returns: The angle in radians.
    ///
    /// This computed property allows for easy conversion of angles from degrees to radians,
    /// which is often required in trigonometric calculations and graphical representations.
    ///
    /// ## Usage Example
    /// ```
    /// let angleDegrees: Double = 180.0
    /// let angleRadians = angleDegrees.toRadians
    /// print(angleRadians) // Output: 3.141592653589793
    /// ```
    var toRadians: Double {
        return self * .pi / 180.0
    }
}
