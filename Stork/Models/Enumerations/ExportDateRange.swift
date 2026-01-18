//
//  ExportDateRange.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation

enum ExportDateRange: String, CaseIterable, Identifiable {
    case thisMonth
    case lastMonth
    case thisYear
    case lastYear
    case allTime
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .thisYear: return "This Year"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
        case .custom: return "Custom Range"
        }
    }

    func dateInterval(from calendar: Calendar = .current) -> DateInterval? {
        let now = Date()

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

        case .allTime:
            return nil // No filtering

        case .custom:
            return nil // Requires external date interval
        }
    }
}

enum CSVRowFormat: String, CaseIterable, Identifiable {
    case perDelivery
    case perBaby

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .perDelivery: return "One Row per Delivery"
        case .perBaby: return "One Row per Baby"
        }
    }

    var description: String {
        switch self {
        case .perDelivery: return "Summary format with baby count"
        case .perBaby: return "Detailed format with individual baby data"
        }
    }
}
