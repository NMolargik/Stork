//
//  DeliveryDestinationView.swift
//  Stork
//

import SwiftUI
import SwiftData

/// Resolves a delivery ID pushed onto a navigation path into its detail view,
/// with a graceful fallback when the delivery no longer exists.
struct DeliveryDestinationView: View {
    @Environment(DeliveryManager.self) private var deliveryManager

    let deliveryId: UUID

    var body: some View {
        if let delivery = deliveryManager.deliveries.first(where: { $0.id == deliveryId }) {
            DeliveryDetailView(delivery: delivery)
        } else {
            ContentUnavailableView(
                "Delivery Not Found",
                systemImage: "exclamationmark.triangle",
                description: Text("The selected delivery could not be loaded.")
            )
        }
    }
}

#Preview("Delivery Not Found") {
    let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Delivery.self, Baby.self, DeliveryTag.self, configurations: config)
    }()

    DeliveryDestinationView(deliveryId: UUID())
        .environment(DeliveryManager(container: container))
}
