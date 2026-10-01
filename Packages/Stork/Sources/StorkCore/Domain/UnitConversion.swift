//
//  UnitConversion.swift
//  StorkCore
//
//  Imperial↔metric math and display formatting for baby measurements. Baby weight is
//  stored in ounces and height in inches; this is the only place those convert.
//  `nonisolated` so the watch and widget can format measurements off the main actor.
//

import Foundation

nonisolated public enum UnitConversion {

    // MARK: - Conversion factors

    public static let ouncesToGrams: Double = 28.349523125
    public static let ouncesToKilograms: Double = 1 / 35.27396
    public static let inchesToCentimeters: Double = 2.54
    public static let centimetersToInches: Double = 0.393701

    // MARK: - Display

    /// Formats weight (stored in ounces) for display.
    public static func weightDisplay(_ ounces: Double, useMetric: Bool) -> String {
        if useMetric {
            let grams = ounces * ouncesToGrams
            return "\(Int(round(grams))) g"
        } else {
            return String(format: "%.1f oz", ounces)
        }
    }

    /// Formats height (stored in inches) for display.
    public static func heightDisplay(_ inches: Double, useMetric: Bool) -> String {
        if useMetric {
            return String(format: "%.1f cm", inches * inchesToCentimeters)
        } else {
            return String(format: "%.1f in", inches)
        }
    }

    /// Compact "lb/oz, ft/in" (or "kg, cm") summary for row displays.
    public static func weightHeightSummary(weightOunces: Double, heightInches: Double, useMetric: Bool) -> String {
        let weightString: String
        let heightString: String

        if useMetric {
            weightString = String(format: "%.1f kg", weightOunces * ouncesToKilograms)
            heightString = String(format: "%.1f cm", heightInches * inchesToCentimeters)
        } else {
            let lbs = Int(weightOunces / 16)
            let oz = Int(weightOunces.truncatingRemainder(dividingBy: 16))
            weightString = "\(lbs) lb \(oz) oz"

            let ft = Int(heightInches / 12)
            let inch = Int(heightInches.truncatingRemainder(dividingBy: 12))
            heightString = ft > 0 ? "\(ft) ft \(inch) in" : "\(inch) in"
        }

        return "\(weightString), \(heightString)"
    }

    // MARK: - Binding conversions (for editing)

    public static func ouncesToDisplayWeight(_ ounces: Double, useMetric: Bool) -> Double {
        useMetric ? ounces * ouncesToGrams : ounces
    }

    public static func displayWeightToOunces(_ value: Double, useMetric: Bool) -> Double {
        useMetric ? value / ouncesToGrams : value
    }

    public static func inchesToDisplayHeight(_ inches: Double, useMetric: Bool) -> Double {
        useMetric ? inches * inchesToCentimeters : inches
    }

    public static func displayHeightToInches(_ value: Double, useMetric: Bool) -> Double {
        useMetric ? value / inchesToCentimeters : value
    }
}
