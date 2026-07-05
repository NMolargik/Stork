//
//  ExportDateRange.swift
//  StorkCore
//
//  Date-range presets for CSV/PDF export plus the CSV row granularity. Pure date math
//  with an injectable calendar.
//

import Foundation

nonisolated public enum ExportDateRange: String, CaseIterable, Identifiable, Sendable {
    case thisMonth
    case lastMonth
    case thisYear
    case lastYear
    case allTime
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .thisMonth: String(localized: "This Month", bundle: .module)
        case .lastMonth: String(localized: "Last Month", bundle: .module)
        case .thisYear: String(localized: "This Year", bundle: .module)
        case .lastYear: String(localized: "Last Year", bundle: .module)
        case .allTime: String(localized: "All Time", bundle: .module)
        case .custom: String(localized: "Custom Range", bundle: .module)
        }
    }

    /// The concrete interval for this preset, or `nil` for `.allTime` (no filter)
    /// and `.custom` (caller supplies the interval).
    public func dateInterval(asOf now: Date = .now, calendar: Calendar = .current) -> DateInterval? {
        switch self {
        case .thisMonth:
            guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
            return DateInterval(start: start, end: min(end, now))

        case .lastMonth:
            guard let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) else { return nil }
            return DateInterval(start: start, end: thisMonthStart)

        case .thisYear:
            guard let start = calendar.date(from: calendar.dateComponents([.year], from: now)),
                  let end = calendar.date(byAdding: .year, value: 1, to: start) else { return nil }
            return DateInterval(start: start, end: min(end, now))

        case .lastYear:
            guard let thisYearStart = calendar.date(from: calendar.dateComponents([.year], from: now)),
                  let start = calendar.date(byAdding: .year, value: -1, to: thisYearStart) else { return nil }
            return DateInterval(start: start, end: thisYearStart)

        case .allTime, .custom:
            return nil
        }
    }
}

nonisolated public enum CSVRowFormat: String, CaseIterable, Identifiable, Sendable {
    case perDelivery
    case perBaby

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .perDelivery: String(localized: "One Row per Delivery", bundle: .module)
        case .perBaby: String(localized: "One Row per Baby", bundle: .module)
        }
    }

    public var description: String {
        switch self {
        case .perDelivery: String(localized: "Summary format with baby count", bundle: .module)
        case .perBaby: String(localized: "Detailed format with individual baby data", bundle: .module)
        }
    }
}
