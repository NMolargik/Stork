//
//  Date+Formatting.swift
//  StorkCore
//
//  Consolidated date formatting helpers shared by view models and views. Pure Foundation.
//

import Foundation

nonisolated public extension Date {
    /// Medium date + short time, e.g. "Jun 28, 2026 at 2:32 PM".
    func formattedMediumDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Delivery-header date. `useDayMonthYear` switches to "dd/MM/yyyy, h:mm a".
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
