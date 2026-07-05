//
//  Delivery.swift
//  StorkCore
//
//  A delivery event: when it happened, how, and the babies born. The denormalized
//  `babyCount` lets widgets and stats sum totals without faulting the `babies`
//  relationship. CloudKit-friendly: every property has a default and relationships
//  are optional.
//

import Foundation
import SwiftData

@Model
public final class Delivery {
    public var id: UUID = UUID()
    public var date: Date = Date.now
    @Relationship(deleteRule: .cascade) public var babies: [Baby]?
    public var babyCount: Int = 0
    public var deliveryMethod: DeliveryMethod = DeliveryMethod.vaginal
    public var epiduralUsed: Bool = false
    public var notes: String?
    @Relationship(inverse: \DeliveryTag.deliveries) public var tags: [DeliveryTag]?

    public init(
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
}

#if DEBUG
public extension Delivery {
    /// A multi-baby sample for previews and tests.
    static func sample() -> Delivery {
        let delivery = Delivery(
            date: .now,
            babyCount: 3,
            deliveryMethod: .vaginal,
            epiduralUsed: true,
            notes: "Twins on Christmas! Such a memorable delivery.",
            tags: []
        )
        delivery.babies = [
            Baby(nurseCatch: true,  nicuStay: false, sex: .male,   weight: 121.6, height: 19.0, birthday: .now, delivery: delivery),
            Baby(nurseCatch: false, nicuStay: true,  sex: .female, weight: 121.6, height: 19.0, birthday: .now, delivery: delivery),
            Baby(nurseCatch: false, nicuStay: false, sex: .loss,   weight: 121.6, height: 19.0, birthday: .now, delivery: delivery),
        ]
        return delivery
    }
}
#endif
