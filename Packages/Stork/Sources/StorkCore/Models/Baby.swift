//
//  Baby.swift
//  StorkCore
//
//  A baby born during a delivery. Measurements are stored imperial (ounces / inches)
//  and converted at display time via `UnitConversion`.
//

import Foundation
import SwiftData

@Model
public final class Baby {
    public var id: UUID = UUID()
    public var birthday: Date = Date.now
    public var height: Double = 0
    public var weight: Double = 0
    public var nurseCatch: Bool = false
    public var nicuStay: Bool = false
    public var sex: Sex = Sex.female

    @Relationship(inverse: \Delivery.babies)
    public var delivery: Delivery?

    public init(
        id: UUID = UUID(),
        birthday: Date = .now,
        height: Double = 0,
        weight: Double = 0,
        nurseCatch: Bool = false,
        nicuStay: Bool = false,
        sex: Sex = .female,
        delivery: Delivery? = nil
    ) {
        self.id = id
        self.birthday = birthday
        self.height = height
        self.weight = weight
        self.nurseCatch = nurseCatch
        self.nicuStay = nicuStay
        self.sex = sex
        self.delivery = delivery
    }

    /// Convenience initializer used by the multi-baby `Delivery.sample()`.
    public convenience init(
        nurseCatch: Bool,
        nicuStay: Bool,
        sex: Sex,
        weight: Double = 121.6,
        height: Double = 19.0,
        birthday: Date = .now,
        delivery: Delivery? = nil
    ) {
        self.init(
            birthday: birthday,
            height: height,
            weight: weight,
            nurseCatch: nurseCatch,
            nicuStay: nicuStay,
            sex: sex,
            delivery: delivery
        )
    }
}

#if DEBUG
public extension Baby {
    /// A customizable sample baby for previews and tests.
    static func sample(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        birthday: Date = Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 28, hour: 14, minute: 32)) ?? .now,
        height: Double = 19.0,
        weight: Double = 121.6,
        nurseCatch: Bool = false,
        nicuStay: Bool = false,
        sex: Sex = .female,
        delivery: Delivery? = nil
    ) -> Baby {
        Baby(
            id: id,
            birthday: birthday,
            height: height,
            weight: weight,
            nurseCatch: nurseCatch,
            nicuStay: nicuStay,
            sex: sex,
            delivery: delivery
        )
    }
}
#endif
