//
//  DeliveryManager.swift
//  Stork
//

import Foundation
import Observation
import SwiftData
import os

#if !os(watchOS)
import UIKit
#endif

/// Owns the delivery list: fetching, CRUD, filtering, and the side effects
/// of a save (widget refresh, milestone celebrations, review prompts).
///
/// Pure logic lives in the domain layer (`DeliveryFilter.matches`,
/// `MilestoneTracker`, `WeekMath`); system frameworks are reached through
/// injected protocol seams so behavior is unit-testable.
@MainActor
@Observable
final class DeliveryManager {

    /// The container is retained here on purpose: `ModelContext` does not
    /// keep its container alive, and a context whose container deallocates
    /// traps on the next operation.
    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let milestoneTracker: MilestoneTracker
    @ObservationIgnored private let widgetReloader: WidgetTimelineReloading
    @ObservationIgnored private let defaults: KeyValueStoring
    #if !os(watchOS)
    @ObservationIgnored private let reviewRequester: ReviewRequesting
    @ObservationIgnored private let indexer: DeliveryIndexing
    #endif

    private(set) var deliveries: [Delivery] = []
    private(set) var currentFilter = DeliveryFilter()

    /// The milestone currently pending celebration (nil if none).
    var pendingMilestoneCelebration: MilestoneCelebration?

    #if os(watchOS)
    init(
        container: ModelContainer,
        milestoneTracker: MilestoneTracker = MilestoneTracker(),
        widgetReloader: WidgetTimelineReloading = WidgetCenterReloader(),
        defaults: KeyValueStoring = UserDefaults.standard
    ) {
        self.container = container
        self.context = container.mainContext
        self.milestoneTracker = milestoneTracker
        self.widgetReloader = widgetReloader
        self.defaults = defaults
        Task { await refresh() }
    }
    #else
    init(
        container: ModelContainer,
        milestoneTracker: MilestoneTracker = MilestoneTracker(),
        widgetReloader: WidgetTimelineReloading = WidgetCenterReloader(),
        defaults: KeyValueStoring = UserDefaults.standard,
        reviewRequester: ReviewRequesting = AppStoreReviewRequester(),
        indexer: DeliveryIndexing = SpotlightDeliveryIndexer()
    ) {
        self.container = container
        self.context = container.mainContext
        self.milestoneTracker = milestoneTracker
        self.widgetReloader = widgetReloader
        self.defaults = defaults
        self.reviewRequester = reviewRequester
        self.indexer = indexer
        Task { await refresh() }
    }
    #endif

    // MARK: - Reading

    var visibleDeliveries: [Delivery] {
        currentFilter.isEmpty ? deliveries : deliveries.filter { currentFilter.matches($0) }
    }

    func applyFilter(_ filter: DeliveryFilter) {
        currentFilter = filter
    }

    func refresh() async {
        do {
            let descriptor = FetchDescriptor<Delivery>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            deliveries = try context.fetch(descriptor)
            #if !os(watchOS)
            // Keep the Spotlight semantic index in sync (covers saves,
            // deletes, and CloudKit imports — every path refreshes).
            indexer.reindex(deliveries)
            #endif
        } catch {
            Log.deliveries.error("Fetch failed: \(error.localizedDescription)")
            deliveries = []
        }
    }

    // MARK: - Writing

    #if os(watchOS)
    func create(delivery: Delivery) {
        createDeliveryInternal(delivery: delivery)
    }
    #else
    func create(delivery: Delivery, reviewScene: UIWindowScene? = nil) {
        createDeliveryInternal(delivery: delivery)
        maybeRequestReviewIfFifthEver(in: reviewScene)
    }
    #endif

    private func createDeliveryInternal(delivery: Delivery) {
        // An entry sheet can re-save an existing delivery; merge instead of duplicating.
        if let existing = deliveries.first(where: { $0.id == delivery.id }) {
            existing.date = delivery.date
            existing.deliveryMethod = delivery.deliveryMethod
            existing.epiduralUsed = delivery.epiduralUsed
            existing.babyCount = delivery.babyCount
            existing.notes = delivery.notes
            existing.tags = delivery.tags
            existing.babies = delivery.babies ?? []
            for baby in existing.babies ?? [] { baby.delivery = existing }
            saveAndReload()
            return
        }

        context.insert(delivery)
        for baby in delivery.babies ?? [] { baby.delivery = delivery }
        saveAndReload()
        checkForMilestones()
    }

    func update(_ delivery: Delivery, _ mutate: (Delivery) -> Void) {
        mutate(delivery)
        for baby in delivery.babies ?? [] { baby.delivery = delivery }
        saveAndReload()
    }

    func delete(_ delivery: Delivery) {
        context.delete(delivery)
        saveAndReload()
    }

    func delete(at offsets: IndexSet) {
        let visible = visibleDeliveries
        for idx in offsets where visible.indices.contains(idx) {
            context.delete(visible[idx])
        }
        saveAndReload()
    }

    func deleteAllDeliveries() {
        for delivery in deliveries {
            context.delete(delivery)
        }
        saveAndReload()
    }

    private func saveAndReload() {
        do {
            try context.save()
        } catch {
            Log.deliveries.error("Save failed: \(error.localizedDescription)")
        }
        Task { await refresh() }
        updateBabiesThisWeekWidget()
    }

    // MARK: - Widget refresh

    private func babiesThisWeekCount() -> Int {
        let week = WeekMath.weekRange()
        let (start, end) = (week.start, week.end)
        var descriptor = FetchDescriptor<Delivery>()
        descriptor.predicate = #Predicate<Delivery> { d in
            d.date >= start && d.date < end
        }
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

    private func updateBabiesThisWeekWidget() {
        // Write fallback values the widgets can read if SwiftData is
        // unavailable in the extension process.
        if let shared = UserDefaults(suiteName: AppGroup.id) {
            shared.set(babiesThisWeekCount(), forKey: SharedDefaultsKey.babiesThisWeekCount)
            let totals = milestoneTotals
            shared.set(totals.babies, forKey: SharedDefaultsKey.careerTotalBabies)
            shared.set(totals.deliveries, forKey: SharedDefaultsKey.careerTotalDeliveries)
        }
        widgetReloader.reloadTimelines(ofKind: WidgetKind.deliveriesThisWeek)
    }

    // MARK: - Milestones

    /// Career totals queried from the store directly — the `deliveries`
    /// array refreshes asynchronously and can be stale right after a save.
    var milestoneTotals: (deliveries: Int, babies: Int) {
        let deliveryCount = (try? context.fetchCount(FetchDescriptor<Delivery>())) ?? deliveries.count
        let babyCount = (try? context.fetchCount(FetchDescriptor<Baby>()))
            ?? deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }
        return (deliveryCount, babyCount)
    }

    func dismissMilestoneCelebration() {
        pendingMilestoneCelebration = nil
    }

    private func checkForMilestones() {
        let totals = milestoneTotals
        if let milestone = milestoneTracker.checkForNewMilestone(
            totalBabies: totals.babies,
            totalDeliveries: totals.deliveries
        ) {
            pendingMilestoneCelebration = milestone
        }
    }

    // MARK: - Review prompting

    #if !os(watchOS)
    private static let reviewPromptFifthKey = "DeliveryManager.hasPromptedForFifthReview"

    /// Asks for an App Store review exactly once, when the 5th delivery is logged.
    private func maybeRequestReviewIfFifthEver(in scene: UIWindowScene?) {
        guard !defaults.bool(forKey: Self.reviewPromptFifthKey) else { return }

        do {
            let count = try context.fetchCount(FetchDescriptor<Delivery>())
            guard count == 5 else { return }
        } catch {
            Log.deliveries.error("Review-prompt count failed: \(error.localizedDescription)")
            return
        }

        defaults.set(true, forKey: Self.reviewPromptFifthKey)

        if let scene {
            reviewRequester.requestReview(in: scene)
        }
    }
    #endif
}
