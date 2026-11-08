//
//  PastBirths.swift
//  StorkCore
//
//  "Add Past Births": turn approximate yearly totals into estimated summary deliveries.
//  Pure and deterministic (injectable `Calendar` / `Date`). One summary `Delivery`
//  (`isEstimated == true`) is made per year, carrying the year's counts instead of
//  individual `Baby` rows. See `Delivery` for the model and `DeliveryStatistics` for
//  where estimated records do and do not count.
//

import Foundation

nonisolated public struct PastBirthsYear: Equatable, Sendable, Identifiable {
    public var year: Int
    /// Approximate deliveries that year.
    public var births: Int
    public var id: Int { year }

    public init(year: Int, births: Int) {
        self.year = year
        self.births = births
    }
}

/// Optional splits, all as whole percentages so one setting scales across years of
/// different sizes. Defaults add nothing: no multiples, no losses, sex unknown.
nonisolated public struct PastBirthsSplits: Equatable, Sendable {
    /// Percent of deliveries that were twins or more (each adds one extra baby).
    public var multiplesPercent: Int = 0
    /// Percent of babies who were losses.
    public var lossesPercent: Int = 0
    /// Percent of live babies who were boys; girls are the rest. nil = sex not tracked.
    public var boysPercent: Int?

    public init(multiplesPercent: Int = 0, lossesPercent: Int = 0, boysPercent: Int? = nil) {
        self.multiplesPercent = multiplesPercent
        self.lossesPercent = lossesPercent
        self.boysPercent = boysPercent
    }
}

nonisolated public enum PastBirthsIssue: Equatable, Sendable {
    case noYears
    case yearOutOfRange(Int)
    case duplicateYear(Int)
    case birthsOutOfRange(year: Int)
    case percentOutOfRange
}

nonisolated public enum PastBirths {

    public static let earliestYear = 1950
    public static let maxBirthsPerYear = 2_000

    /// One entry per year in `from...to`, each with `average` births.
    public static func years(from: Int, to: Int, average: Int) -> [PastBirthsYear] {
        guard from <= to else { return [] }
        return (from...to).map { PastBirthsYear(year: $0, births: average) }
    }

    public static func validate(
        _ years: [PastBirthsYear],
        splits: PastBirthsSplits = PastBirthsSplits(),
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [PastBirthsIssue] {
        var issues: [PastBirthsIssue] = []
        if years.isEmpty { issues.append(.noYears) }
        let currentYear = calendar.component(.year, from: now)
        var seen = Set<Int>()
        for entry in years {
            if entry.year < earliestYear || entry.year > currentYear { issues.append(.yearOutOfRange(entry.year)) }
            if !seen.insert(entry.year).inserted { issues.append(.duplicateYear(entry.year)) }
            if entry.births < 0 || entry.births > maxBirthsPerYear { issues.append(.birthsOutOfRange(year: entry.year)) }
        }
        let percents = [splits.multiplesPercent, splits.lossesPercent, splits.boysPercent ?? 0]
        if percents.contains(where: { $0 < 0 || $0 > 100 }) { issues.append(.percentOutOfRange) }
        return issues
    }

    /// The counts one year turns into.
    public struct Counts: Equatable, Sendable {
        public let deliveries: Int
        public let babies: Int
        public let boys: Int
        public let girls: Int
        public let losses: Int
    }

    public static func counts(births: Int, splits: PastBirthsSplits) -> Counts {
        let births = max(0, births)
        let extras = percent(splits.multiplesPercent, of: births)
        let babies = births + extras
        let losses = min(babies, percent(splits.lossesPercent, of: babies))
        let live = babies - losses
        var boys = 0, girls = 0
        if let boysPercent = splits.boysPercent {
            boys = min(live, percent(boysPercent, of: live))
            girls = live - boys
        }
        return Counts(deliveries: births, babies: babies, boys: boys, girls: girls, losses: losses)
    }

    private static func percent(_ value: Int, of total: Int) -> Int {
        Int((Double(total) * Double(min(max(value, 0), 100)) / 100).rounded())
    }

    /// The placeholder date a year's summary sits at: noon on July 1, or `now` if that is
    /// still in the future (the current year). The exact day never matters because
    /// estimated records are skipped by every day/month/time statistic.
    public static func placeholderDate(forYear year: Int, now: Date = .now, calendar: Calendar = .current) -> Date {
        let midYear = calendar.date(from: DateComponents(year: year, month: 7, day: 1, hour: 12)) ?? now
        return min(midYear, now)
    }

    /// Builds the estimated summary deliveries (years with zero births are skipped).
    @MainActor
    public static func makeDeliveries(
        years: [PastBirthsYear],
        splits: PastBirthsSplits = PastBirthsSplits(),
        role: BirthRole? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Delivery] {
        years.sorted { $0.year < $1.year }.compactMap { entry in
            guard entry.births > 0 else { return nil }
            let c = counts(births: entry.births, splits: splits)
            let delivery = Delivery(
                date: placeholderDate(forYear: entry.year, now: now, calendar: calendar),
                babyCount: c.babies,
                deliveryMethod: .vaginal,
                epiduralUsed: false,
                role: role
            )
            delivery.isEstimated = true
            delivery.estimatedDeliveries = c.deliveries
            delivery.estimatedBoys = c.boys
            delivery.estimatedGirls = c.girls
            delivery.estimatedLosses = c.losses
            return delivery
        }
    }
}
