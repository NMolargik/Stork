//
//  DeliveryIndexing.swift
//  StorkCore
//
//  Seam over the Spotlight semantic index so the delivery-indexing side effect can be
//  verified in tests without CoreSpotlight. The concrete indexer lives in `StorkData`.
//
//  HIPAA: indexers must expose aggregate fields only (date, counts, method, epidural) —
//  never notes or tags, which can hold free text.
//

import Foundation

@MainActor
public protocol DeliveryIndexing {
    /// Replaces the index contents with entries for `deliveries`.
    func reindex(_ deliveries: [Delivery])
}
