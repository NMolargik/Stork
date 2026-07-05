//
//  DashboardCard.swift
//  StorkCore
//
//  The reorderable statistic cards on the Dashboard. The jar visualization is always
//  pinned to the top and is not part of this list. Order persistence is provided via
//  the injectable `KeyValueStoring` seam so it is testable.
//

import Foundation

nonisolated public enum DashboardCard: String, CaseIterable, Codable, Identifiable, Sendable {
    case deliveryMethod
    case epiduralNicu
    case babyCount
    case babyMeasurements
    case sexDistribution
    case timeOfDay
    case dayOfWeek
    case yearOverYear
    case personalBests

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .deliveryMethod: "Delivery Method"
        case .epiduralNicu: "Epidural & NICU"
        case .babyCount: "Baby Count"
        case .babyMeasurements: "Baby Measurements"
        case .sexDistribution: "Sex Distribution"
        case .timeOfDay: "Time of Day"
        case .dayOfWeek: "Day of Week"
        case .yearOverYear: "Year Over Year"
        case .personalBests: "Personal Bests"
        }
    }

    public var systemImage: String {
        switch self {
        case .deliveryMethod: "figure.and.child.holdinghands"
        case .epiduralNicu: "syringe"
        case .babyCount: "number"
        case .babyMeasurements: "ruler"
        case .sexDistribution: "figure.dress.line.vertical.figure"
        case .timeOfDay: "clock"
        case .dayOfWeek: "calendar"
        case .yearOverYear: "chart.line.uptrend.xyaxis"
        case .personalBests: "trophy"
        }
    }

    /// The default order is simply declaration order.
    public static var defaultOrder: [DashboardCard] { allCases }

    /// The saved order, backfilling any cards added since it was written.
    public static func loadOrder(from store: KeyValueStoring) -> [DashboardCard] {
        guard let data = store.data(forKey: AppStorageKeys.dashboardCardOrder),
              let order = try? JSONDecoder().decode([DashboardCard].self, from: data) else {
            return defaultOrder
        }
        var result = order.filter { defaultOrder.contains($0) }
        for card in defaultOrder where !result.contains(card) {
            result.append(card)
        }
        return result
    }

    /// Persists the order through the key-value seam.
    public static func saveOrder(_ order: [DashboardCard], to store: KeyValueStoring) {
        if let data = try? JSONEncoder().encode(order) {
            store.set(data, forKey: AppStorageKeys.dashboardCardOrder)
        }
    }
}
