import Foundation
import Observation
import UIKit
import WidgetKit
import StoreKit
import SwiftData

enum AppGroup {
    static let id = "group.com.molargiksoftware.Stork"
}

@MainActor
@Observable
class DeliveryManager {
    static var shared: DeliveryManager? = nil
    
    @ObservationIgnored
    private let context: ModelContext
    
    private(set) var deliveries: [Delivery] = []
    private var currentFilter: DeliveryFilter = DeliveryFilter()
    
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
                guard matchesMethod else { return false }
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
        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM yy")
        let str = df.string(from: monthStart).uppercased()
        if let range = str.range(of: " ") {
            let month = String(str[..<range.lowerBound])
            let year = String(str[range.upperBound...])
            return "\(month) '\(year)"
        }
        return str
    }
    
    nonisolated static let deliveryCreatedNotification = Notification.Name("DeliveryManager.deliveryCreated")
    
    func create(delivery: Delivery, reviewScene: UIWindowScene? = nil) {
        // Prevent duplicate insert if a delivery with the same id is already tracked
        if let existing = deliveries.first(where: { $0.id == delivery.id }) {
            // Optionally merge top-level fields, but do not insert
            existing.date = delivery.date
            existing.hospitalId = delivery.hospitalId
            existing.deliveryMethod = delivery.deliveryMethod
            existing.epiduralUsed = delivery.epiduralUsed
            existing.babyCount = delivery.babyCount
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
        
        Task { await maybeRequestReviewIfFifthEver(in: reviewScene) }
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
    
    private func saveAndReload() {
        do {
            try context.save()
        } catch {
            print(DeliveryError.creationFailed(error.localizedDescription))
        }
        Task { await refresh() }
    }
    
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
}

