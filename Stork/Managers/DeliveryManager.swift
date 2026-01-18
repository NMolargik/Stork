import Foundation
import Observation
import WidgetKit
import SwiftData

#if !os(watchOS)
import UIKit
import StoreKit
#endif

enum AppGroup {
    static let id = "group.com.molargiksoftware.Stork"
}

@MainActor
@Observable
class DeliveryManager {
    static var shared: DeliveryManager? = nil

    @ObservationIgnored
    private let context: ModelContext

    /// Cached DateFormatter for header titles
    private static let headerDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM yy")
        return df
    }()

    private(set) var deliveries: [Delivery] = []
    private var currentFilter: DeliveryFilter = DeliveryFilter()

    // MARK: - Milestone Celebration
    /// Milestone thresholds for babies delivered
    static let babyMilestones: [Int] = [100, 250, 500, 1000, 2500, 5000, 10000]
    /// Milestone thresholds for deliveries completed
    static let deliveryMilestones: [Int] = [50, 100, 250, 500, 1000, 2500, 5000]

    /// The milestone currently pending celebration (nil if none)
    var pendingMilestoneCelebration: MilestoneCelebration?

    /// Represents a milestone that should be celebrated
    struct MilestoneCelebration: Equatable {
        let count: Int
        let type: MilestoneType

        enum MilestoneType: String {
            case babies
            case deliveries
        }
    }

    private static let celebratedMilestonesKey = "DeliveryManager.celebratedMilestones"

    private var celebratedMilestones: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: Self.celebratedMilestonesKey) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Self.celebratedMilestonesKey)
        }
    }

    func dismissMilestoneCelebration() {
        pendingMilestoneCelebration = nil
    }
    
    var visibleDeliveries: [Delivery] {
        deliveries.filter { delivery in
            if let dateRange = currentFilter.dateRange {
                guard dateRange.contains(delivery.date) else { return false }
            }

            if let babyCount = currentFilter.babyCount {
                guard delivery.babyCount == babyCount else { return false }
            }

            if !currentFilter.deliveryMethod.isEmpty {
                guard currentFilter.deliveryMethod.contains(delivery.deliveryMethod) else { return false }
            }

            if currentFilter.epiduralUsedOnly {
                guard delivery.epiduralUsed else { return false }
            }

            if !currentFilter.searchText.isEmpty {
                let searchText = currentFilter.searchText.lowercased()
                let matchesMethod = delivery.deliveryMethod.rawValue.lowercased().contains(searchText)
                let matchesNotes = delivery.notes?.lowercased().contains(searchText) ?? false
                guard matchesMethod || matchesNotes else { return false }
            }

            // Tag filtering: show delivery if it has ANY of the selected tags
            if !currentFilter.selectedTagIds.isEmpty {
                let deliveryTagIds = Set((delivery.tags ?? []).map { $0.id })
                guard !deliveryTagIds.isDisjoint(with: currentFilter.selectedTagIds) else { return false }
            }

            // Notes filtering: show only deliveries that have notes
            if currentFilter.hasNotesOnly {
                guard let notes = delivery.notes, !notes.isEmpty else { return false }
            }

            return true
        }
    }
    
    private(set) var oldestLoadedMonthStart: Date?
    private(set) var anchorMonthStart: Date?
    
    var monthSectionStarts: [Date] {
        guard let oldest = oldestLoadedMonthStart else { return [] }
        let anchor = anchorMonthStart ?? startOfMonth(for: Date())
        var out: [Date] = []
        var cursor = anchor
        let cal = Calendar.current
        while cursor >= oldest {
            out.append(cursor)
            cursor = cal.date(byAdding: .month, value: -1, to: cursor) ?? cursor
            if out.count > 240 { break }
        }
        return out
    }
    
    init(context: ModelContext) {
        self.context = context
        DeliveryManager.shared = self
        Task { await refresh() }
    }
    
    func applyFilter(_ filter: DeliveryFilter) {
        self.currentFilter = filter
    }
    
    func refresh() async {
        do {
            let desc = FetchDescriptor<Delivery>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let fetched = try context.fetch(desc)
            self.deliveries = fetched
            print("Loaded \(deliveries.count) deliveries.")
        } catch {
            print(DeliveryError.fetchFailed(error.localizedDescription))
            self.deliveries = []
        }
    }
    
    func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }
    
    private func startOfNextMonth(after date: Date) -> Date {
        let cal = Calendar.current
        let start = startOfMonth(for: date)
        return cal.date(byAdding: .month, value: 1, to: start) ?? date
    }
    
    private func monthStart(monthsAgo: Int, from date: Date = Date()) -> Date {
        let cal = Calendar.current
        let start = startOfMonth(for: date)
        return cal.date(byAdding: .month, value: -monthsAgo, to: start) ?? start
    }
    
    func headerTitle(for monthStart: Date) -> String {
        let str = Self.headerDateFormatter.string(from: monthStart).uppercased()
        if let range = str.range(of: " ") {
            let month = String(str[..<range.lowerBound])
            let year = String(str[range.upperBound...])
            return "\(month) '\(year)"
        }
        return str
    }
    
    nonisolated static let deliveryCreatedNotification = Notification.Name("DeliveryManager.deliveryCreated")
    
    #if os(watchOS)
    func create(delivery: Delivery) {
        createDeliveryInternal(delivery: delivery)
    }
    #else
    func create(delivery: Delivery, reviewScene: UIWindowScene? = nil) {
        createDeliveryInternal(delivery: delivery)
        Task { await maybeRequestReviewIfFifthEver(in: reviewScene) }
    }
    #endif

    private func createDeliveryInternal(delivery: Delivery) {
        // Prevent duplicate insert if a delivery with the same id is already tracked
        if let existing = deliveries.first(where: { $0.id == delivery.id }) {
            // Optionally merge top-level fields, but do not insert
            existing.date = delivery.date
            existing.deliveryMethod = delivery.deliveryMethod
            existing.epiduralUsed = delivery.epiduralUsed
            existing.babyCount = delivery.babyCount
            existing.notes = delivery.notes
            existing.tags = delivery.tags
            // Replace babies carefully, preserving inverse relationships
            let newBabies = delivery.babies ?? []
            existing.babies = newBabies
            for baby in existing.babies ?? [] { baby.delivery = existing }
            saveAndReload()
            return
        }

        context.insert(delivery)
        // Ensure inverse relationship for babies is correct
        for baby in delivery.babies ?? [] { baby.delivery = delivery }
        saveAndReload()

        // Check for milestone celebrations
        checkForMilestones()
    }
    
    func update(_ delivery: Delivery, _ mutate: (Delivery) -> Void) {
        mutate(delivery) // Apply the mutation closure
        // Ensure inverse relationships are consistent after mutation
        for baby in delivery.babies ?? [] { baby.delivery = delivery }
        saveAndReload()
    }
    
    func delete(_ delivery: Delivery) {
        context.delete(delivery)
        saveAndReload()
    }
    
    func delete(at offsets: IndexSet) {
        for idx in offsets {
            guard idx >= 0 && idx < visibleDeliveries.count else { continue }
            let model = visibleDeliveries[idx]
            context.delete(model)
        }
        saveAndReload()
    }
    
    func deleteAllDeliveries() {
        for d in deliveries {
            context.delete(d)
        }
        saveAndReload()
    }
    
    private func currentWeekRangeSundayToSaturday() -> (start: Date, end: Date) {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        cal.firstWeekday = 1 // Sunday
        cal.minimumDaysInFirstWeek = 1
        
        let now = Date()
        let weekday = cal.component(.weekday, from: now) // Sun=1 ... Sat=7
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -(weekday - 1), to: now)!)
        let end = cal.date(byAdding: .day, value: 7, to: start)! // exclusive
        return (start, end)
    }
    
    private func babiesThisWeekCount() -> Int {
        let (start, end) = currentWeekRangeSundayToSaturday()
        var desc = FetchDescriptor<Delivery>()
        desc.predicate = #Predicate<Delivery> { d in
            d.date >= start && d.date < end
        }
        do {
            let weekly = try context.fetch(desc)
            // Prefer deriving from deliveries: use delivery.babyCount (fast) and fallback to relationship if needed
            let total = weekly.reduce(0) { sum, d in
                let byField = d.babyCount
                let byRel = d.babies?.count ?? 0
                return sum + (byField > 0 ? byField : byRel)
            }
            return max(0, total)
        } catch {
            print("Failed to compute babiesThisWeekCount: \(error)")
            return 0
        }
    }
    
    private func updateBabiesThisWeekWidget() {
        // Write a fallback value the widget can read if SwiftData is unavailable
        if let defaults = UserDefaults(suiteName: AppGroup.id) {
            defaults.set(babiesThisWeekCount(), forKey: "babiesThisWeekCount")
        }
        // Ask WidgetKit to refresh the timeline for our widget kind
        WidgetCenter.shared.reloadTimelines(ofKind: "DeliveriesThisWeekWidget")
    }
    
    private func saveAndReload() {
        do {
            try context.save()
        } catch {
            print(DeliveryError.creationFailed(error.localizedDescription))
        }
        Task { await refresh() }
        updateBabiesThisWeekWidget()
    }
    
    #if !os(watchOS)
    private static let reviewPromptFifthKey = "DeliveryManager.hasPromptedForFifthReview"

    private func maybeRequestReviewIfFifthEver(in scene: UIWindowScene?) async {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Self.reviewPromptFifthKey) {
            return
        }

        do {
            let count = try context.fetchCount(FetchDescriptor<Delivery>())
            guard count == 5 else { return }
        } catch {
            print(DeliveryError.fetchFailed(error.localizedDescription))
            return
        }

        defaults.set(true, forKey: Self.reviewPromptFifthKey)

        if let scene {
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
    #endif

    // MARK: - Milestone Checking

    private func checkForMilestones() {
        // Calculate totals
        let totalDeliveries = deliveries.count
        let totalBabies = deliveries.reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }

        // Check baby milestones (higher priority)
        for milestone in Self.babyMilestones.reversed() {
            let key = "babies-\(milestone)"
            if totalBabies >= milestone && !celebratedMilestones.contains(key) {
                celebratedMilestones.insert(key)
                pendingMilestoneCelebration = MilestoneCelebration(count: milestone, type: .babies)
                return
            }
        }

        // Check delivery milestones
        for milestone in Self.deliveryMilestones.reversed() {
            let key = "deliveries-\(milestone)"
            if totalDeliveries >= milestone && !celebratedMilestones.contains(key) {
                celebratedMilestones.insert(key)
                pendingMilestoneCelebration = MilestoneCelebration(count: milestone, type: .deliveries)
                return
            }
        }
    }
}
