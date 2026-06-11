//
//  DeliveryEntity.swift
//  Stork
//
//  The Siri / Spotlight / Apple Intelligence representation of a delivery.
//  HIPAA-conscious by construction: aggregate facts only (date, counts,
//  method, epidural) — never notes or tags, which can hold free text.
//

import AppIntents
import CoreSpotlight
import Foundation

struct DeliveryEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Delivery")
    static let defaultQuery = DeliveryEntityQuery()

    var id: UUID

    @Property(title: "Date")
    var date: Date

    @Property(title: "Babies")
    var babyCount: Int

    @Property(title: "Delivery Method")
    var method: DeliveryMethod

    @Property(title: "Epidural Used")
    var epiduralUsed: Bool

    /// Feeds Spotlight's semantic index so the new Siri can reason over
    /// the entity ("the C-section with twins last week").
    @ComputedProperty(indexingKey: \.contentDescription)
    var summary: String {
        "\(babyCount) \(babyCount == 1 ? "baby" : "babies"), \(method.displayName) delivery, \(epiduralUsed ? "with" : "without") epidural"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(babyCount) \(babyCount == 1 ? "baby" : "babies")",
            subtitle: "\(date.formatted(date: .abbreviated, time: .shortened)) — \(method.displayName)"
        )
    }

    @MainActor
    init(from delivery: Delivery) {
        self.id = delivery.id
        self.date = delivery.date
        self.babyCount = delivery.babies?.count ?? delivery.babyCount
        self.method = delivery.deliveryMethod
        self.epiduralUsed = delivery.epiduralUsed
    }
}

// MARK: - Query

struct DeliveryEntityQuery: EntityQuery {
    @Dependency
    private var deliveryManager: DeliveryManager

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [DeliveryEntity] {
        await deliveryManager.refresh()
        let wanted = Set(identifiers)
        return deliveryManager.deliveries
            .filter { wanted.contains($0.id) }
            .map(DeliveryEntity.init(from:))
    }

    @MainActor
    func suggestedEntities() async throws -> [DeliveryEntity] {
        await deliveryManager.refresh()
        return deliveryManager.deliveries
            .prefix(10)
            .map(DeliveryEntity.init(from:))
    }
}

// MARK: - Open intent

/// Lets Spotlight results and Siri open a specific delivery in the app.
struct OpenDeliveryIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Delivery"
    static let description = IntentDescription(
        "Opens a delivery's details in Stork.",
        categoryName: "Deliveries"
    )

    @Parameter(title: "Delivery")
    var target: DeliveryEntity

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "stork://delivery/\(target.id.uuidString)")!))
    }
}
