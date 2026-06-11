//
//  SpotlightDeliveryIndexer.swift
//  Stork
//
//  Keeps the Spotlight semantic index in sync with the delivery store so
//  the new Siri / Apple Intelligence can reason over deliveries (with
//  attribution back to Stork). Only DeliveryEntity's aggregate fields are
//  indexed — never notes or tags.
//

import AppIntents
import CoreSpotlight
import Foundation
import os

struct SpotlightDeliveryIndexer: DeliveryIndexing {
    nonisolated init() {}

    func reindex(_ deliveries: [Delivery]) {
        let entities = deliveries.map(DeliveryEntity.init(from:))
        Task {
            // Named index per Apple guidance (the default index is not for
            // production). Created inside the task region: CSSearchableIndex
            // is not Sendable and must not cross isolation boundaries.
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
