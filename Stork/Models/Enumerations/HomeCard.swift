//
//  HomeCard.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation

/// Represents the reorderable cards on the Home screen.
/// JarView is always at the top and is not included here.
enum HomeCard: String, CaseIterable, Codable, Identifiable {
    case deliveryMethod = "deliveryMethod"
    case epiduralNicu = "epiduralNicu"  // Unified Epidural + NICU row
    case babyCount = "babyCount"
    case babyMeasurements = "babyMeasurements"
    case sexDistribution = "sexDistribution"
    case timeOfDay = "timeOfDay"
    case dayOfWeek = "dayOfWeek"
    case yearOverYear = "yearOverYear"
    case personalBests = "personalBests"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .deliveryMethod: return "Delivery Method"
        case .epiduralNicu: return "Epidural & NICU"
        case .babyCount: return "Baby Count"
        case .babyMeasurements: return "Baby Measurements"
        case .sexDistribution: return "Sex Distribution"
        case .timeOfDay: return "Time of Day"
        case .dayOfWeek: return "Day of Week"
        case .yearOverYear: return "Year Over Year"
        case .personalBests: return "Personal Bests"
        }
    }

    var systemImage: String {
        switch self {
        case .deliveryMethod: return "figure.and.child.holdinghands"
        case .epiduralNicu: return "syringe"
        case .babyCount: return "number"
        case .babyMeasurements: return "ruler"
        case .sexDistribution: return "figure.dress.line.vertical.figure"
        case .timeOfDay: return "clock"
        case .dayOfWeek: return "calendar"
        case .yearOverYear: return "chart.line.uptrend.xyaxis"
        case .personalBests: return "trophy"
        }
    }

    /// Default order of cards
    static var defaultOrder: [HomeCard] {
        return allCases
    }

    /// Load saved order from UserDefaults, or return default
    static func loadOrder() -> [HomeCard] {
        guard let data = UserDefaults.standard.data(forKey: AppStorageKeys.homeCardOrder),
              let order = try? JSONDecoder().decode([HomeCard].self, from: data) else {
            return defaultOrder
        }
        // Ensure all cards are present (in case new cards were added)
        var result = order.filter { defaultOrder.contains($0) }
        for card in defaultOrder where !result.contains(card) {
            result.append(card)
        }
        return result
    }

    /// Save order to UserDefaults
    static func saveOrder(_ order: [HomeCard]) {
        if let data = try? JSONEncoder().encode(order) {
            UserDefaults.standard.set(data, forKey: AppStorageKeys.homeCardOrder)
        }
    }
}
