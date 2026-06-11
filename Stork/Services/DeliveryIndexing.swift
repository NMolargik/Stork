//
//  DeliveryIndexing.swift
//  Stork
//

import Foundation

/// Seam over the Spotlight semantic index so DeliveryManager's indexing
/// side effect can be verified in tests without CoreSpotlight.
@MainActor
protocol DeliveryIndexing {
    /// Replaces the index contents with entities for `deliveries`.
    func reindex(_ deliveries: [Delivery])
}
