//
//  DeliveryModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

public struct Delivery: Identifiable, Codable, Hashable {
    public var id: String
    public var userId: String
    public var userFirstName: String
    public var hospitalId: String
    public var musterId: String
    public var date: Date
    public var babies: [Baby]
    public var babyCount: Int
    public var deliveryMethod: DeliveryMethod
    public var epiduralUsed: Bool

    // Converts the `DeliveryModel` into a dictionary format suitable for Firestore storage.
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "userFirstName": userFirstName,
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
    public init?(from dictionary: [String: Any], id: String?) {
        guard
            let id = id,
            let userId = dictionary["userId"] as? String,
            let userFirstName = dictionary["userFirstName"] as? String,
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
        self.userId = userId
        self.userFirstName = userFirstName
        self.hospitalId = hospitalId
        self.musterId = musterId
        self.date = Date(timeIntervalSince1970: dateTimestamp)
        self.babies = babiesData.compactMap { Baby(from: $0) }
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
    }

    // A standard initializer for creating a new `DeliveryModel` instance.
    public init(id: String, userId: String, userFirstName: String, hospitalId: String, musterId: String, date: Date, babies: [Baby], babyCount: Int, deliveryMethod: DeliveryMethod, epiduralUsed: Bool) {
        self.id = id
        self.userId = userId
        self.userFirstName = userFirstName
        self.hospitalId = hospitalId
        self.musterId = musterId
        self.date = date
        self.babies = babies
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
    }
    
    public init(sample: Bool) {
        self.id = UUID().uuidString
        self.userId = UUID().uuidString
        self.userFirstName = "FirstName"
        self.hospitalId = "1234"
        self.musterId = "5678"
        self.date = Date()
        self.babies = [
            Baby(deliveryId: "12345", nurseCatch: true, sex: Sex.male),
            Baby(deliveryId: "12345", nurseCatch: false, sex: Sex.female),
            Baby(deliveryId: "12345", nurseCatch: false, sex: Sex.loss),
        ]
        self.babyCount = 3
        self.deliveryMethod = DeliveryMethod.vaginal
        self.epiduralUsed = true
    }
}
