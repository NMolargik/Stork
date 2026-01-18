//
//  UnitConversion.swift
//  Stork
//
//  Consolidated unit conversion helpers for weight and height.
//

import Foundation

/// Conversion factors for unit conversions
enum UnitConversion {
    // MARK: - Weight Conversion Factors
    /// Ounces to grams
    static let ouncesToGrams: Double = 28.349523125
    /// Ounces to kilograms (for summary display)
    static let ouncesToKilograms: Double = 1 / 35.27396

    // MARK: - Height Conversion Factors
    /// Inches to centimeters
    static let inchesToCentimeters: Double = 2.54
    /// Centimeters to inches (inverse)
    static let centimetersToInches: Double = 0.393701

    // MARK: - Weight Display

    /// Formats weight (stored in ounces) for display
    /// - Parameters:
    ///   - ounces: Weight in ounces
    ///   - useMetric: Whether to display in metric units (grams)
    /// - Returns: Formatted weight string
    static func weightDisplay(_ ounces: Double, useMetric: Bool) -> String {
        if useMetric {
            let grams = ounces * ouncesToGrams
            return "\(Int(round(grams))) g"
        } else {
            return String(format: "%.1f oz", ounces)
        }
    }

    // MARK: - Height Display

    /// Formats height (stored in inches) for display
    /// - Parameters:
    ///   - inches: Height in inches
    ///   - useMetric: Whether to display in metric units (centimeters)
    /// - Returns: Formatted height string
    static func heightDisplay(_ inches: Double, useMetric: Bool) -> String {
        if useMetric {
            let cm = inches * inchesToCentimeters
            return String(format: "%.1f cm", cm)
        } else {
            return String(format: "%.1f in", inches)
        }
    }

    // MARK: - Weight/Height Summary (for row displays)

    /// Formats weight and height for compact row display (lbs/oz or kg format)
    /// - Parameters:
    ///   - weightOunces: Weight in ounces
    ///   - heightInches: Height in inches
    ///   - useMetric: Whether to display in metric units
    /// - Returns: Formatted summary string
    static func weightHeightSummary(weightOunces: Double, heightInches: Double, useMetric: Bool) -> String {
        let weightString: String
        let heightString: String

        if useMetric {
            let weightKg = weightOunces * ouncesToKilograms
            weightString = String(format: "%.1f kg", weightKg)
            let heightCm = heightInches * inchesToCentimeters
            heightString = String(format: "%.1f cm", heightCm)
        } else {
            let totalOunces = weightOunces
            let lbs = Int(totalOunces / 16)
            let oz = Int(totalOunces.truncatingRemainder(dividingBy: 16))
            weightString = "\(lbs) lb \(oz) oz"

            let totalInches = heightInches
            let ft = Int(totalInches / 12)
            let inch = Int(totalInches.truncatingRemainder(dividingBy: 12))
            heightString = ft > 0 ? "\(ft) ft \(inch) in" : "\(inch) in"
        }

        return "\(weightString), \(heightString)"
    }

    // MARK: - Binding Conversions (for editing)

    /// Converts stored ounces to display value
    static func ouncesToDisplayWeight(_ ounces: Double, useMetric: Bool) -> Double {
        useMetric ? ounces * ouncesToGrams : ounces
    }

    /// Converts display value back to stored ounces
    static func displayWeightToOunces(_ value: Double, useMetric: Bool) -> Double {
        useMetric ? value / ouncesToGrams : value
    }

    /// Converts stored inches to display value
    static func inchesToDisplayHeight(_ inches: Double, useMetric: Bool) -> Double {
        useMetric ? inches * inchesToCentimeters : inches
    }

    /// Converts display value back to stored inches
    static func displayHeightToInches(_ value: Double, useMetric: Bool) -> Double {
        useMetric ? value / inchesToCentimeters : value
    }
}
