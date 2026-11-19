import Testing
import Foundation
import StorkCore
@testable import StorkFeatureExport

@Suite("Report period")
struct ReportPeriodTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    @Test func thisYearRunsFromJanuaryFirstToToday() {
        let now = date(2026, 11, 19)
        let days = ReportPeriod.days(range: .thisYear, custom: nil, deliveryDates: [], now: now, calendar: calendar)
        #expect(calendar.component(.month, from: days!.start) == 1)
        #expect(calendar.component(.day, from: days!.start) == 1)
        #expect(days!.end == now)
    }

    @Test func lastYearEndsOnDecemberThirtyFirst() {
        let days = ReportPeriod.days(range: .lastYear, custom: nil, deliveryDates: [], now: date(2026, 11, 19), calendar: calendar)
        #expect(calendar.component(.year, from: days!.end) == 2025)
        #expect(calendar.component(.month, from: days!.end) == 12)
        #expect(calendar.component(.day, from: days!.end) == 31)
    }

    @Test func allTimeUsesFirstAndLastDelivery() {
        let days = ReportPeriod.days(range: .allTime, custom: nil, deliveryDates: [date(2025, 3, 2), date(2024, 1, 9), date(2026, 5, 1)], now: .now, calendar: calendar)
        #expect(days!.start == date(2024, 1, 9))
        #expect(days!.end == date(2026, 5, 1))
        #expect(ReportPeriod.days(range: .allTime, custom: nil, deliveryDates: [], now: .now, calendar: calendar) == nil)
    }
}
