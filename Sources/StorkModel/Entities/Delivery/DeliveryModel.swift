//
//  DeliveryModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

public struct Delivery: Identifiable, Codable, Hashable {
    public var id: String
    var hospitalId: String
    var musterId: String
    var date: Date
    var babies: [Baby]
    var babyCount: Int
    var deliveryMethod: DeliveryMethod
    var epiduralUsed: Bool

    // Converts the `DeliveryModel` into a dictionary format suitable for Firestore storage.
    var dictionary: [String: Any] {
        return [
            "id": id,
            "hospitalId": hospitalId,
            "musterId": musterId,
            "date": date.timeIntervalSince1970,
            "babies": babies.map { $0.dictionary },
            "babyCount": babyCount,
            "deliveryMethod": deliveryMethod.rawValue,
            "epiduralUsed": epiduralUsed
        ]
    }

    // Initializes a `DeliveryModel` from a Firestore data dictionary.
    init?(from dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let hospitalId = dictionary["hospitalId"] as? String,
            let musterId = dictionary["musterId"] as? String,
            let dateTimestamp = dictionary["date"] as? TimeInterval,
            let babiesData = dictionary["babies"] as? [[String: Any]],
            let babyCount = dictionary["babyCount"] as? Int,
            let deliveryMethodRawValue = dictionary["deliveryMethod"] as? String,
            let deliveryMethod = DeliveryMethod(rawValue: deliveryMethodRawValue),
            let epiduralUsed = dictionary["epiduralUsed"] as? Bool
        else {
            return nil
        }

        self.id = id
        self.hospitalId = hospitalId
        self.musterId = musterId
        self.date = Date(timeIntervalSince1970: dateTimestamp)
        self.babies = babiesData.compactMap { Baby(from: $0) }
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
    }

    // A standard initializer for creating a new `DeliveryModel` instance.
    init(id: String, hospitalId: String, musterId: String, date: Date, babies: [Baby], babyCount: Int, deliveryMethod: DeliveryMethod, epiduralUsed: Bool) {
        self.id = id
        self.hospitalId = hospitalId
        self.musterId = musterId
        self.date = date
        self.babies = babies
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
    }
}
