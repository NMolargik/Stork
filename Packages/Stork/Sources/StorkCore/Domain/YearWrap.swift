//
//  YearWrap.swift
//  StorkCore
//
//  "Your Year in Births": the pure statistics behind the year-end Wrap. Everything is a
//  deterministic function of the deliveries, the chosen calendar year, the user's "what
//  counts toward my total" role setting, and an injectable `Calendar`.
//
//  Losses are never celebrated. Every headline number (deliveries, babies, boys, girls,
//  multiples, busiest month/day, streak, first/last birth, comparison) is computed over
//  live births only; losses surface solely as the separate `remembrance` count.
//

import Foundation

nonisolated public struct YearWrapStats: Equatable, Sendable {
    public struct Day: Equatable, Sendable {
        public let date: Date
        public let deliveries: Int
        public let babies: Int
    }

    public struct Month: Equatable, Sendable {
        /// 1...12.
        public let month: Int
        public let monthStart: Date
        public let deliveries: Int
        public let babies: Int
    }

    public struct RoleCount: Equatable, Identifiable, Sendable {
        public let role: BirthRole
        public let deliveries: Int
        public let babies: Int
        public var id: BirthRole { role }
    }

    public struct Comparison: Equatable, Sendable {
        public let previousYear: Int
        public let deliveries: Int
        public let babies: Int
        /// This year minus last year.
        public let deliveryChange: Int
        public let babyChange: Int
        /// Percent change in babies versus last year (nil when last year had none).
        public let babyPercentChange: Double?
    }

    public let year: Int
    /// Deliveries with at least one baby born (losses-only deliveries are not celebrated).
    public let deliveries: Int
    /// Babies born, excluding losses.
    public let babies: Int
    public let boys: Int
    public let girls: Int
    public let nurseCatches: Int
    /// Deliveries of exactly two babies born.
    public let twinSets: Int
    /// Deliveries of three or more babies born.
    public let higherMultipleSets: Int
    public let vaginal: Int
    public let cSection: Int
    public let vBac: Int
    /// Recorded roles only, most deliveries first.
    public let roles: [RoleCount]
    public let busiestMonth: Month?
    public let busiestDay: Day?
    /// Longest run of consecutive days with a delivery.
    public let longestStreak: Int
    public let firstBirth: Date?
    public let lastBirth: Date?
    /// Babies born in each month, January first (always 12 entries).
    public let babiesByMonth: [Int]
    /// Losses, kept entirely apart from every figure above.
    public let remembrance: Int
    public let comparison: Comparison?

    /// Deliveries of two or more babies.
    public var multipleSets: Int { twinSets + higherMultipleSets }
    public var hasRoles: Bool { !roles.isEmpty }
}

public enum YearWrap {

    /// Years (newest first) that have at least one celebrated delivery.
    public static func availableYears(
        deliveries: [Delivery],
        counting: BirthRoleCounting = BirthRoleCounting(),
        calendar: Calendar = .current
    ) -> [Int] {
        var years: Set<Int> = []
        for delivery in deliveries where counting.counts(delivery.role) && liveBabies(delivery) > 0 {
            years.insert(calendar.component(.year, from: delivery.date))
        }
        return years.sorted(by: >)
    }

    /// Builds the Wrap for `year`, or nil when that year has no celebrated delivery.
    public static func build(
        deliveries all: [Delivery],
        year: Int,
        counting: BirthRoleCounting = BirthRoleCounting(),
        calendar: Calendar = .current
    ) -> YearWrapStats? {
        let counted = all.filter { counting.counts($0.role) }
        let inYear = counted.filter { calendar.component(.year, from: $0.date) == year }
        let live = inYear.filter { liveBabies($0) > 0 }
        guard !live.isEmpty else { return nil }

        var babies = 0, boys = 0, girls = 0, nurseCatches = 0
        var twinSets = 0, higherSets = 0
        var vaginal = 0, cSection = 0, vBac = 0
        var byMonthBabies = [Int](repeating: 0, count: 12)
        var byMonthDeliveries = [Int](repeating: 0, count: 12)
        var byDay: [Date: (deliveries: Int, babies: Int)] = [:]
        var roleTotals: [BirthRole: (deliveries: Int, babies: Int)] = [:]

        for delivery in live {
            let n = liveBabies(delivery)
            babies += n
            let kids = (delivery.babies ?? []).filter { $0.sex != .loss }
            boys += kids.count { $0.sex == .male }
            girls += kids.count { $0.sex == .female }
            nurseCatches += kids.count { $0.nurseCatch }
            if n == 2 { twinSets += 1 } else if n > 2 { higherSets += 1 }
            switch delivery.deliveryMethod {
            case .vaginal: vaginal += 1
            case .cSection: cSection += 1
            case .vBac: vBac += 1
            }
            let monthIndex = calendar.component(.month, from: delivery.date) - 1
            byMonthBabies[monthIndex] += n
            byMonthDeliveries[monthIndex] += 1
            let day = calendar.startOfDay(for: delivery.date)
            let existing = byDay[day] ?? (0, 0)
            byDay[day] = (existing.deliveries + 1, existing.babies + n)
            if let role = delivery.role {
                let current = roleTotals[role] ?? (0, 0)
                roleTotals[role] = (current.deliveries + 1, current.babies + n)
            }
        }

        let roles = BirthRole.allCases.compactMap { role -> YearWrapStats.RoleCount? in
            guard let t = roleTotals[role] else { return nil }
            return .init(role: role, deliveries: t.deliveries, babies: t.babies)
        }
        .sorted { $0.deliveries > $1.deliveries }

        // Busiest month: most deliveries, then most babies, then the earlier month.
        var busiestMonth: YearWrapStats.Month?
        for index in 0..<12 where byMonthDeliveries[index] > 0 {
            let candidate = (byMonthDeliveries[index], byMonthBabies[index])
            if let best = busiestMonth, (best.deliveries, best.babies) >= candidate { continue }
            let start = calendar.date(from: DateComponents(year: year, month: index + 1, day: 1)) ?? Date()
            busiestMonth = .init(month: index + 1, monthStart: start, deliveries: byMonthDeliveries[index], babies: byMonthBabies[index])
        }

        // Busiest day: most deliveries, then most babies, then the earlier day.
        let sortedDays = byDay.keys.sorted()
        var busiestDay: YearWrapStats.Day?
        for day in sortedDays {
            let value = byDay[day]!
            if let best = busiestDay, (best.deliveries, best.babies) >= (value.deliveries, value.babies) { continue }
            busiestDay = .init(date: day, deliveries: value.deliveries, babies: value.babies)
        }

        var longest = 0, run = 0
        var previous: Date?
        for day in sortedDays {
            if let previous, calendar.dateComponents([.day], from: previous, to: day).day == 1 { run += 1 } else { run = 1 }
            longest = max(longest, run)
            previous = day
        }

        let dates = live.map(\.date)
        let remembrance = inYear.reduce(0) { $0 + lossBabies($1) }

        return YearWrapStats(
            year: year,
            deliveries: live.count,
            babies: babies,
            boys: boys,
            girls: girls,
            nurseCatches: nurseCatches,
            twinSets: twinSets,
            higherMultipleSets: higherSets,
            vaginal: vaginal,
            cSection: cSection,
            vBac: vBac,
            roles: roles,
            busiestMonth: busiestMonth,
            busiestDay: busiestDay,
            longestStreak: longest,
            firstBirth: dates.min(),
            lastBirth: dates.max(),
            babiesByMonth: byMonthBabies,
            remembrance: remembrance,
            comparison: comparison(counted: counted, year: year, babies: babies, deliveries: live.count, calendar: calendar)
        )
    }

    // MARK: - Helpers

    private static func comparison(counted: [Delivery], year: Int, babies: Int, deliveries: Int, calendar: Calendar) -> YearWrapStats.Comparison? {
        let previous = counted.filter { calendar.component(.year, from: $0.date) == year - 1 && liveBabies($0) > 0 }
        guard !previous.isEmpty else { return nil }
        let previousBabies = previous.reduce(0) { $0 + liveBabies($1) }
        return .init(
            previousYear: year - 1,
            deliveries: previous.count,
            babies: previousBabies,
            deliveryChange: deliveries - previous.count,
            babyChange: babies - previousBabies,
            babyPercentChange: previousBabies > 0 ? Double(babies - previousBabies) / Double(previousBabies) * 100 : nil
        )
    }

    /// Babies born in a delivery, excluding losses. Falls back to the denormalized
    /// `babyCount` for legacy deliveries without baby rows.
    static func liveBabies(_ delivery: Delivery) -> Int {
        if let babies = delivery.babies, !babies.isEmpty { return babies.count { $0.sex != .loss } }
        return delivery.babyCount
    }

    static func lossBabies(_ delivery: Delivery) -> Int {
        (delivery.babies ?? []).count { $0.sex == .loss }
    }
}

/// When the dashboard invites the user to view their Wrap.
nonisolated public enum YearWrapSeason {
    /// The year being wrapped while the invitation is showing: December 1 through January 31
    /// (the year just ending). Nil outside that window.
    public static func promptYear(now: Date, calendar: Calendar = .current) -> Int? {
        let parts = calendar.dateComponents([.year, .month], from: now)
        guard let year = parts.year, let month = parts.month else { return nil }
        switch month {
        case 12: return year
        case 1: return year - 1
        default: return nil
        }
    }
}
