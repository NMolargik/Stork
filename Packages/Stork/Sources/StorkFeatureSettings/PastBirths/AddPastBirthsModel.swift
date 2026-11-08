//
//  AddPastBirthsModel.swift
//  StorkFeatureSettings
//
//  Backs "Add Past Births": approximate totals per year (a range with a per-year
//  average, or year-by-year) with optional splits. The math lives in `PastBirths`
//  (Core); this model gathers the form, validates, and saves through `ImportDeliveries`.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class AddPastBirthsModel {

    public enum Mode: Hashable, Sendable { case range, yearByYear }

    public struct Row: Identifiable, Equatable, Sendable {
        public let id = UUID()
        public var year: Int
        public var births: Int?
        public init(year: Int, births: Int? = nil) { self.year = year; self.births = births }
    }

    private let importDeliveries: any ImportDeliveries
    private let now: () -> Date
    private let calendar: Calendar

    public var mode: Mode = .range
    public var rangeStart: Int
    public var rangeEnd: Int
    public var averagePerYear: Int?
    public var rows: [Row]

    public var role: BirthRole?
    public var multiplesPercent: Int?
    public var lossesPercent: Int?
    /// Boys as a percentage of live babies (girls are the rest). nil = sex not tracked.
    public var boysPercent: Int?

    public private(set) var lastError: PersistenceError?
    public private(set) var savedBirths: Int?

    public init(
        importDeliveries: any ImportDeliveries,
        now: @escaping () -> Date = { Date() },
        calendar: Calendar = .current
    ) {
        self.importDeliveries = importDeliveries
        self.now = now
        self.calendar = calendar
        let year = calendar.component(.year, from: now())
        rangeEnd = year - 1
        rangeStart = year - 5
        rows = [Row(year: year - 1)]
    }

    public var currentYear: Int { calendar.component(.year, from: now()) }
    public var selectableYears: [Int] { Array((PastBirths.earliestYear...currentYear).reversed()) }

    public var years: [PastBirthsYear] {
        switch mode {
        case .range:
            guard let averagePerYear else { return [] }
            return PastBirths.years(from: rangeStart, to: rangeEnd, average: averagePerYear)
        case .yearByYear:
            return rows.compactMap { row in row.births.map { PastBirthsYear(year: row.year, births: $0) } }
        }
    }

    public var splits: PastBirthsSplits {
        PastBirthsSplits(multiplesPercent: multiplesPercent ?? 0, lossesPercent: lossesPercent ?? 0, boysPercent: boysPercent)
    }

    public var issues: [PastBirthsIssue] {
        var found = PastBirths.validate(years, splits: splits, now: now(), calendar: calendar)
        if mode == .range && rangeStart > rangeEnd { found.append(.noYears) }
        return found
    }

    /// What saving would add, for the live summary line.
    public var totals: (years: Int, deliveries: Int, babies: Int) {
        let valid = years.filter { $0.births > 0 }
        let counts = valid.map { PastBirths.counts(births: $0.births, splits: splits) }
        return (valid.count, counts.reduce(0) { $0 + $1.deliveries }, counts.reduce(0) { $0 + $1.babies })
    }

    public var canSave: Bool { issues.isEmpty && totals.deliveries > 0 }

    public func addRow() {
        let used = Set(rows.map(\.year))
        let year = selectableYears.first { !used.contains($0) } ?? currentYear
        rows.append(Row(year: year))
    }

    public func removeRows(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where rows.indices.contains(index) { rows.remove(at: index) }
    }

    /// Saves the estimated summaries in one transaction. Returns whether it worked.
    @discardableResult
    public func save() -> Bool {
        guard canSave else { return false }
        let deliveries = PastBirths.makeDeliveries(years: years, splits: splits, role: role, now: now(), calendar: calendar)
        do {
            try importDeliveries(deliveries)
            savedBirths = deliveries.reduce(0) { $0 + $1.deliveryWeight }
            lastError = nil
            return true
        } catch {
            lastError = error
            return false
        }
    }
}
