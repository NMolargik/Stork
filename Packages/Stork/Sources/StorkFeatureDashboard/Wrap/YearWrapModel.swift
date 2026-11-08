//
//  YearWrapModel.swift
//  StorkFeatureDashboard
//
//  View model for the Year Wrap story. Cross-platform so it tests on the host: it holds the
//  deliveries it was given, the chosen year, and the share options, and delegates every
//  number to the pure `YearWrap` builder in Core.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class YearWrapModel {

    public enum Page: Equatable, Hashable, Sendable {
        case intro, arrivals, roles, rhythm, comparison, summary
    }

    public enum ShareFormat: String, CaseIterable, Identifiable, Sendable {
        case square, story
        public var id: String { rawValue }
    }

    private let deliveries: [Delivery]
    private let counting: BirthRoleCounting
    private let store: any KeyValueStoring
    private let calendar: Calendar

    public let years: [Int]
    public private(set) var year: Int
    public private(set) var stats: YearWrapStats?
    public var shareFormat: ShareFormat = .story

    /// Whether the shared image carries the gentle remembrance line. Off by default and
    /// remembered across launches.
    public var includeRemembranceOnImage: Bool {
        didSet { store.set(includeRemembranceOnImage, forKey: AppStorageKeys.wrapShareIncludesRemembrance) }
    }

    public init(
        deliveries: [Delivery],
        year: Int,
        counting: BirthRoleCounting,
        store: any KeyValueStoring = UserDefaults.standard,
        calendar: Calendar = .current
    ) {
        self.deliveries = deliveries
        self.counting = counting
        self.store = store
        self.calendar = calendar
        self.years = YearWrap.availableYears(deliveries: deliveries, counting: counting, calendar: calendar)
        self.year = year
        self.includeRemembranceOnImage = store.bool(forKey: AppStorageKeys.wrapShareIncludesRemembrance)
        self.stats = YearWrap.build(deliveries: deliveries, year: year, counting: counting, calendar: calendar)
    }

    public func select(year newYear: Int) {
        guard years.contains(newYear) else { return }
        year = newYear
        stats = YearWrap.build(deliveries: deliveries, year: newYear, counting: counting, calendar: calendar)
    }

    /// The story's pages, skipping any the data cannot support.
    public var pages: [Page] {
        guard let stats else { return [] }
        var result: [Page] = [.intro, .arrivals]
        if stats.hasRoles { result.append(.roles) }
        result.append(.rhythm)
        if stats.comparison != nil { result.append(.comparison) }
        result.append(.summary)
        return result
    }

    /// The remembrance count to print on the share image (nil when the user left it off
    /// or there is nothing to remember).
    public var remembranceForImage: Int? {
        guard includeRemembranceOnImage, let stats, stats.remembrance > 0 else { return nil }
        return stats.remembrance
    }
}
