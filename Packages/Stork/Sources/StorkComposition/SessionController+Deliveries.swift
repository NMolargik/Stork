//
//  SessionController+Deliveries.swift
//  StorkComposition
//
//  View-model factories for the Deliveries feature. Each `make…Model()` builds a fresh
//  view model wired to the session's use-cases.
//

import StorkCore
import StorkFeatureDeliveries

public extension SessionController {
    /// A delivery list model. Wire `onRemoteDeliveriesChange` to its `load()` so CloudKit
    /// imports refresh the list mid-session.
    func makeDeliveryListModel() -> DeliveryListModel {
        DeliveryListModel(
            loadDeliveries: loadDeliveries,
            deleteDelivery: deleteDelivery,
            loadTags: loadTags
        )
    }

    /// A new-or-edit delivery entry model.
    func makeDeliveryEntryModel(existing: Delivery? = nil) -> DeliveryEntryModel {
        DeliveryEntryModel(
            existingDelivery: existing,
            logDelivery: logDelivery,
            updateDelivery: updateDelivery,
            loadTags: loadTags,
            saveTag: saveTag
        )
    }
}
