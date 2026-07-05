//
//  DefaultDeliveryRepository.swift
//  StorkData
//
//  The SwiftData-backed `DeliveryRepository`. Owns the `ModelContext` and runs every
//  save's side effects in one place — app-group fallback counts, widget refresh, the
//  Spotlight reindex, and the one-time "5th delivery" review prompt — so no caller can
//  forget them. Pure logic (milestones, week math) stays in `StorkCore`; system
//  frameworks are reached through injected seams.
//

import Foundation
import SwiftData
import StorkCore
import os

@MainActor
public final class DefaultDeliveryRepository: DeliveryRepository {

    /// Retained on purpose: a `ModelContext` does not keep its container alive, and a
    /// context whose container deallocates traps on the next operation.
    private let container: ModelContainer
    private let context: ModelContext
    private let milestoneTracker: MilestoneTracker
    private let widgetReloader: any WidgetTimelineReloading
    private let defaults: any KeyValueStoring
    private let indexer: (any DeliveryIndexing)?
    private let reviewRequester: (any ReviewRequesting)?
    private let changeCenter: DeliveryChangeCenter?

    private static let reviewPromptFifthKey = "DeliveryManager.hasPromptedForFifthReview"

    public init(
        container: ModelContainer,
        defaults: any KeyValueStoring = UserDefaults.standard,
        widgetReloader: any WidgetTimelineReloading = WidgetCenterReloader(),
        milestoneTracker: MilestoneTracker? = nil,
        indexer: (any DeliveryIndexing)? = nil,
        reviewRequester: (any ReviewRequesting)? = nil,
        changeCenter: DeliveryChangeCenter? = nil
    ) {
        self.container = container
        self.context = container.mainContext
        self.defaults = defaults
        self.widgetReloader = widgetReloader
        self.milestoneTracker = milestoneTracker ?? MilestoneTracker(storage: defaults)
        self.indexer = indexer
        self.reviewRequester = reviewRequester
        self.changeCenter = changeCenter
    }

    // MARK: - Reading

    public func deliveries() throws(PersistenceError) -> [Delivery] {
        do {
            return try context.fetch(
                FetchDescriptor<Delivery>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            )
        } catch {
            Log.deliveries.error("Fetch failed: \(error.localizedDescription)")
            throw .fetchFailed(error.localizedDescription)
        }
    }

    public func careerTotals() -> CareerTotals {
        CareerTotals(
            deliveries: (try? context.fetchCount(FetchDescriptor<Delivery>())) ?? 0,
            babies: (try? context.fetchCount(FetchDescriptor<Baby>())) ?? 0
        )
    }

    // MARK: - Writing

    @discardableResult
    public func add(_ delivery: Delivery) throws(PersistenceError) -> MilestoneCelebration? {
        context.insert(delivery)
        for baby in delivery.babies ?? [] { baby.delivery = delivery }
        try persistAndPropagate()
        maybeRequestReviewIfFifthEver()
        return checkForMilestone()
    }

    public func update(_ delivery: Delivery) throws(PersistenceError) {
        for baby in delivery.babies ?? [] { baby.delivery = delivery }
        try persistAndPropagate()
    }

    public func delete(_ delivery: Delivery) throws(PersistenceError) {
        context.delete(delivery)
        try persistAndPropagate()
    }

    public func deleteAll() throws(PersistenceError) {
        // One transaction, then one side-effect pass — not N widget/Spotlight refreshes.
        for delivery in try deliveries() {
            context.delete(delivery)
        }
        try persistAndPropagate()
    }

    // MARK: - Persistence + side effects

    private func persistAndPropagate() throws(PersistenceError) {
        do {
            try context.save()
        } catch {
            Log.deliveries.error("Save failed: \(error.localizedDescription)")
            throw .saveFailed(error.localizedDescription)
        }
        writeSharedCounts()
        widgetReloader.reloadTimelines(ofKind: WidgetKind.deliveriesThisWeek)
        reindexSpotlight()
        changeCenter?.notify()
    }

    private func reindexSpotlight() {
        guard let indexer else { return }
        if let all = try? deliveries() {
            indexer.reindex(all)
        }
    }

    // MARK: - Widget / app-group fallback counts

    private func writeSharedCounts() {
        guard let shared = UserDefaults(suiteName: AppGroup.id) else { return }
        shared.set(babiesThisWeekCount(), forKey: SharedDefaultsKey.babiesThisWeekCount)
        let totals = careerTotals()
        shared.set(totals.babies, forKey: SharedDefaultsKey.careerTotalBabies)
        shared.set(totals.deliveries, forKey: SharedDefaultsKey.careerTotalDeliveries)
    }

    private func babiesThisWeekCount() -> Int {
        let week = WeekMath.weekRange()
        let (start, end) = (week.start, week.end)
        var descriptor = FetchDescriptor<Delivery>()
        descriptor.predicate = #Predicate<Delivery> { $0.date >= start && $0.date < end }
        do {
            let weekly = try context.fetch(descriptor)
            let total = weekly.reduce(0) { sum, d in
                let byField = d.babyCount
                let byRelationship = d.babies?.count ?? 0
                return sum + (byField > 0 ? byField : byRelationship)
            }
            return max(0, total)
        } catch {
            Log.deliveries.error("Failed to compute babiesThisWeekCount: \(error.localizedDescription)")
            return 0
        }
    }

    // MARK: - Milestones

    private func checkForMilestone() -> MilestoneCelebration? {
        let totals = careerTotals()
        return milestoneTracker.checkForNewMilestone(
            totalBabies: totals.babies,
            totalDeliveries: totals.deliveries
        )
    }

    // MARK: - Review prompting

    /// Asks for an App Store review exactly once, when the 5th delivery is logged.
    private func maybeRequestReviewIfFifthEver() {
        guard let reviewRequester else { return }
        guard !defaults.bool(forKey: Self.reviewPromptFifthKey) else { return }
        guard careerTotals().deliveries == 5 else { return }
        defaults.set(true, forKey: Self.reviewPromptFifthKey)
        reviewRequester.requestReview()
    }
}
