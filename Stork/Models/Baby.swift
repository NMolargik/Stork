//
//  Baby.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation
import SwiftData

/// Represents a baby born during a delivery within the Stork application.
@Model
final class Baby {
    var id: UUID = UUID()
    var birthday: Date = Date.now
    var height: Double = 0
    var weight: Double = 0
    var nurseCatch: Bool = false
    var nicuStay: Bool = false
    var sex: Sex = Sex.female

    @Relationship(inverse: \Delivery.babies)
    var delivery: Delivery?

    init(
        id: UUID = UUID(),
        birthday: Date = .now,
        height: Double = 0,
        weight: Double = 0,
        nurseCatch: Bool = false,
        nicuStay: Bool = false,
        sex: Sex = .male,
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

    convenience init(nurseCatch: Bool, nicuStay: Bool, sex: Sex, weight: Double = 121.6, height: Double = 19.0, birthday: Date = Date(), delivery: Delivery? = nil) {
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

    static let sample: Baby = {
        let baby = Baby(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            birthday: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 28, hour: 14, minute: 32)) ?? .now,
            height: 19.5,
            weight: 122.0,
            nurseCatch: true,
            nicuStay: false,
            sex: .male,
            delivery: nil
        )
        return baby
    }()

    /// Returns a customizable sample baby for previews and tests
    /// - Parameters mirror the model with sensible defaults
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
