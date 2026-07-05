//
//  SpotlightDeliveryIndexer.swift
//  Stork
//
//  Keeps the Spotlight semantic index in sync with the delivery store so the new Siri /
//  Apple Intelligence can reason over deliveries. Conforms to the `DeliveryIndexing` seam
//  and is injected into the `SessionController`. Only `DeliveryEntity`'s aggregate fields
//  are indexed — never notes or tags.
//

import AppIntents
import CoreSpotlight
import Foundation
import os
import StorkCore

struct SpotlightDeliveryIndexer: DeliveryIndexing {
    /// Signature of the last indexed state — refresh runs often; re-donating identical
    /// content churns the Spotlight XPC service for nothing.
    @MainActor private static var lastSignature: Int?

    init() {}

    func reindex(_ deliveries: [Delivery]) {
        let entities = deliveries.map(DeliveryEntity.init(from:))

        var hasher = Hasher()
        for entity in entities {
            hasher.combine(entity.id)
            hasher.combine(entity.date)
            hasher.combine(entity.babyCount)
            hasher.combine(entity.method)
            hasher.combine(entity.epiduralUsed)
        }
        let signature = hasher.finalize()
        guard signature != Self.lastSignature else { return }
        Self.lastSignature = signature

        Task {
            let index = CSSearchableIndex(name: "StorkDeliveries")
            do {
                try await index.deleteAppEntities(ofType: DeliveryEntity.self)
                try await index.indexAppEntities(entities, priority: 0)
            } catch {
                Log.app.error("Spotlight reindex failed: \(error.localizedDescription)")
            }
        }
    }
}
