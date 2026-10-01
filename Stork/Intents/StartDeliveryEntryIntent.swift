//
//  StartDeliveryEntryIntent.swift
//  Stork
//

import AppIntents
import Foundation

/// Opens Stork directly to the full delivery entry form.
struct StartDeliveryEntryIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a New Delivery"
    static let description = IntentDescription(
        "Opens Stork to the new delivery form.",
        categoryName: "Deliveries"
    )

    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "stork://new-delivery")!))
    }
}
