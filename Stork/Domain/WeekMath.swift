//
//  WeekMath.swift
//  Stork
//

import Foundation

/// Calendar math shared by the app, widget, and watch targets.
///
/// Stork weeks run Sunday through Saturday regardless of locale, matching
/// the cadence of U.S. nursing schedules.
enum WeekMath {

    /// A Sunday-to-Saturday week. `end` is the following Sunday at 00:00 (exclusive).
    struct WeekRange: Equatable {
        let start: Date
        let end: Date

        func contains(_ date: Date) -> Bool {
            date >= start && date < end
        }
    }

    /// Gregorian calendar pinned to Sunday-first weeks.
    static let sundayFirstCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.firstWeekday = 1
        cal.minimumDaysInFirstWeek = 1
        return cal
    }()

    /// The Sunday-to-Saturday week containing `date`.
    static func weekRange(containing date: Date = Date(), calendar: Calendar = sundayFirstCalendar) -> WeekRange {
        let weekday = calendar.component(.weekday, from: date) // Sun=1 ... Sat=7
        let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(weekday - 1), to: date) ?? date)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? date
        return WeekRange(start: start, end: end)
    }

    /// Midnight on the first day of the month containing `date`.
    static func startOfMonth(for date: Date, calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    /// First-of-month dates from `anchor` back to `oldest`, newest first.
    /// Capped at 240 months as a runaway guard.
    static func monthStarts(from oldest: Date, anchor: Date, calendar: Calendar = .current) -> [Date] {
        var out: [Date] = []
        var cursor = anchor
        while cursor >= oldest {
            out.append(cursor)
            guard let previous = calendar.date(byAdding: .month, value: -1, to: cursor) else { break }
            cursor = previous
            if out.count > 240 { break }
        }
        return out
    }

    /// Formats a week range like "Jun 7 – Jun 13".
    static func formattedWeekString(_ range: WeekRange) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.setLocalizedDateFormatFromTemplate("MMM d")
        let startText = df.string(from: range.start)
        let lastDay = sundayFirstCalendar.date(byAdding: .day, value: -1, to: range.end) ?? range.end
        return "\(startText) – \(df.string(from: lastDay))"
    }

    /// Section header like "JUN '26" for a month-start date.
    static func monthHeaderTitle(for monthStart: Date) -> String {
        let str = monthHeaderFormatter.string(from: monthStart).uppercased()
        if let range = str.range(of: " ") {
            let month = String(str[..<range.lowerBound])
            let year = String(str[range.upperBound...])
            return "\(month) '\(year)"
        }
        return str
    }

    private static let monthHeaderFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM yy")
        return df
    }()
}
