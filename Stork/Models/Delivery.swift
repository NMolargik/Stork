//
//  Delivery.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation
import SwiftData

/// Represents a delivery event within the Stork application.
@Model
final class Delivery {
    var id: UUID = UUID()
    var date: Date = Date.now
    @Relationship(deleteRule: .cascade) var babies: [Baby]?
    var babyCount: Int = 0
    var deliveryMethod: DeliveryMethod = DeliveryMethod.vaginal
    var epiduralUsed: Bool = false
    var notes: String?
    @Relationship(inverse: \DeliveryTag.deliveries) var tags: [DeliveryTag]?

    init(
        id: UUID = UUID(),
        date: Date,
        babies: [Baby] = [],
        babyCount: Int,
        deliveryMethod: DeliveryMethod,
        epiduralUsed: Bool,
        notes: String? = nil,
        tags: [DeliveryTag] = []
    ) {
        self.id = id
        self.date = date
        self.babies = babies
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
        self.notes = notes
        self.tags = tags
    }

    static func sample() -> Delivery {
        let delivery = Delivery(
            date: Date(),
            babyCount: 3,
            deliveryMethod: .vaginal,
            epiduralUsed: true,
            notes: "Twins on Christmas! Such a memorable delivery.",
            tags: []
        )
        let b1 = Baby(nurseCatch: true, nicuStay: false, sex: .male, weight: 121.6, height: 19.0, birthday: Date(), delivery: delivery)
        let b2 = Baby(nurseCatch: false, nicuStay: true, sex: .female, weight: 121.6, height: 19.0, birthday: Date(), delivery: delivery)
        let b3 = Baby(nurseCatch: false, nicuStay: false, sex: .loss, weight: 121.6, height: 19.0, birthday: Date(), delivery: delivery)
        delivery.babies = [b1, b2, b3]
        return delivery
    }
}

