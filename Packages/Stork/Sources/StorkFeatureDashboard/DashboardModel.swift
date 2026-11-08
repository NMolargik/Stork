//
//  DashboardModel.swift
//  StorkFeatureDashboard
//
//  Loads deliveries for the dashboard and owns the persisted card order. Statistics math
//  stays in `DeliveryStatistics` (pure, unit-tested); this model just supplies the data.
//

import Foundation
import Observation
import StorkCore

@MainActor
@Observable
public final class DashboardModel {

    private let loadDeliveriesUseCase: any LoadDeliveries
    private let store: any KeyValueStoring
    private let entitlement: any EntitlementProviding

    public private(set) var deliveries: [Delivery] = []
    public var cardOrder: [DashboardCard]

    /// The Wrap year currently presented (sheet), set by the dashboard card or toolbar menu.
    public var presentedWrapYear: Int?
    private let now: () -> Date

    public init(
        loadDeliveries: any LoadDeliveries,
        entitlement: any EntitlementProviding,
        store: any KeyValueStoring = UserDefaults.standard,
        now: @escaping () -> Date = { Date() }
    ) {
        self.loadDeliveriesUseCase = loadDeliveries
        self.entitlement = entitlement
        self.store = store
        #if DEBUG
        self.now = { DebugLaunchOptions.now ?? now() }
        #else
        self.now = now
        #endif
        self.cardOrder = DashboardCard.loadOrder(from: store)
    }

    // MARK: - Stork Pro

    public var isProUnlocked: Bool { entitlement.isProUnlocked }

    /// Insight cards render as a locked teaser for free users (the data is never hidden —
    /// the basic count cards stay available).
    public func isLocked(_ card: DashboardCard) -> Bool {
        card.requiresPro && !isProUnlocked
    }

    public func load() {
        deliveries = (try? loadDeliveriesUseCase()) ?? []
        cardOrder = DashboardCard.loadOrder(from: store)
    }

    public func refresh() async { load() }

    public func saveOrder(_ order: [DashboardCard]) {
        cardOrder = order
        DashboardCard.saveOrder(order, to: store)
    }

    /// Individually logged deliveries (the jar, calendar and month pages skip estimated
    /// past-birth summaries because those have no real date).
    public var loggedDeliveries: [Delivery] { DeliveryStatistics.logged(deliveries) }

    /// Babies from estimated past-birth summaries, shown as a footnote under the jar.
    public var estimatedBabyCount: Int {
        deliveries.reduce(0) { $0 + ($1.isEstimated ? $1.babyCount : 0) }
    }

    public var monthlyJarCounts: (boy: Int, girl: Int, loss: Int) {
        DeliveryStatistics.monthlyJarCounts(deliveries: deliveries)
    }

    /// One marble per baby this month, categorized for the jar.
    public var jarMarbles: [JarMarble] {
        DeliveryStatistics.jarMarbles(deliveries: deliveries)
    }

    public func jarCounts(forMonthStarting monthStart: Date) -> (boy: Int, girl: Int, loss: Int) {
        DeliveryStatistics.monthlyJarCounts(deliveries: deliveries, asOf: monthStart)
    }

    // MARK: - Year Wrap (free for everyone; deliberately not gated by Stork Pro)

    /// Years that have a Wrap, newest first, honoring the "what counts toward my total" setting.
    public func wrapYears(counting: BirthRoleCounting) -> [Int] {
        YearWrap.availableYears(deliveries: deliveries, counting: counting)
    }

    /// The year to invite the user to view (December 1 through January 31, the year just
    /// ending), or nil when out of season, already dismissed, or that year has no data.
    public func wrapPromptYear(counting: BirthRoleCounting) -> Int? {
        guard let year = YearWrapSeason.promptYear(now: now()),
              store.integer(forKey: AppStorageKeys.wrapPromptDismissedYear) != year,
              wrapYears(counting: counting).contains(year) else { return nil }
        return year
    }

    public func dismissWrapPrompt(year: Int) {
        store.set(year, forKey: AppStorageKeys.wrapPromptDismissedYear)
    }

    public func makeWrapModel(year: Int, counting: BirthRoleCounting) -> YearWrapModel {
        YearWrapModel(deliveries: deliveries, year: year, counting: counting, store: store)
    }
}
