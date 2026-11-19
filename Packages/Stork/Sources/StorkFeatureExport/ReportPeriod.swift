//
//  ReportPeriod.swift
//  StorkFeatureExport
//
//  The concrete dates a PDF report covers, shown under its title. Pure Foundation.
//

import Foundation
import StorkCore

nonisolated enum ReportPeriod {
    /// The first and last day the report covers. Presets use their interval (an interval that ends
    /// exactly at a month or year boundary ends the day before); All Time uses the first and last
    /// delivery; nil when there is nothing to say.
    static func days(range: ExportDateRange, custom: DateInterval?, deliveryDates: [Date], now: Date = .now, calendar: Calendar = .current) -> (start: Date, end: Date)? {
        switch range {
        case .custom:
            guard let custom else { return nil }
            return (custom.start, custom.end)
        case .allTime:
            guard let first = deliveryDates.min(), let last = deliveryDates.max() else { return nil }
            return (first, last)
        case .thisMonth, .thisYear:
            guard let interval = range.dateInterval(asOf: now, calendar: calendar) else { return nil }
            return (interval.start, interval.end)
        case .lastMonth, .lastYear:
            guard let interval = range.dateInterval(asOf: now, calendar: calendar),
                  let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) else { return nil }
            return (interval.start, lastDay)
        }
    }
}
