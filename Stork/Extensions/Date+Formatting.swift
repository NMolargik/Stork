//
//  Date+Formatting.swift
//  Stork
//
//  Consolidated date formatting helpers.
//

import Foundation

extension Date {
    /// Formats date with medium date style and short time style
    func formattedMediumDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Formats date for display in delivery headers
    /// - Parameter useDayMonthYear: If true, uses dd/MM/yyyy format; otherwise uses long date style
    func formattedForDelivery(useDayMonthYear: Bool) -> String {
        let formatter = DateFormatter()
        if useDayMonthYear {
            formatter.dateFormat = "dd/MM/yyyy, h:mm a"
        } else {
            formatter.dateStyle = .long
            formatter.timeStyle = .short
        }
        return formatter.string(from: self)
    }
}
