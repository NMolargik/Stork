//
//  StatsIntents.swift
//  Stork
//
//  Read-only intents that expose Stork's aggregate statistics to Siri,
//  Shortcuts, and Apple Intelligence. Counts only — no patient data.
//

import AppIntents
import Foundation

struct BabiesThisWeekIntent: AppIntent {
    static let title: LocalizedStringResource = "Babies This Week"
    static let description = IntentDescription(
        "How many babies you've delivered this week (Sunday through Saturday).",
        categoryName: "Statistics"
    )

    @Dependency
    private var deliveryManager: DeliveryManager

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        await deliveryManager.refresh()

        let week = WeekMath.weekRange()
        let count = deliveryManager.deliveries
            .filter { week.contains($0.date) }
            .reduce(0) { $0 + ($1.babies?.count ?? $1.babyCount) }

        return .result(
            value: count,
            dialog: count == 0
                ? "No babies delivered yet this week."
                : "You've delivered \(count) \(count == 1 ? "baby" : "babies") this week."
        )
    }
}

struct CareerTotalsIntent: AppIntent {
    static let title: LocalizedStringResource = "Career Delivery Totals"
    static let description = IntentDescription(
        "Your career totals: deliveries performed and babies delivered.",
        categoryName: "Statistics"
    )

    @Dependency
    private var deliveryManager: DeliveryManager

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Int> {
        await deliveryManager.refresh()

        let totals = deliveryManager.milestoneTotals

        return .result(
            value: totals.babies,
            dialog: "You've delivered \(totals.babies) \(totals.babies == 1 ? "baby" : "babies") across \(totals.deliveries) \(totals.deliveries == 1 ? "delivery" : "deliveries"). Incredible work!"
        )
    }
}
