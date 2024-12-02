//
//  BabyModel.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

public struct Baby: Identifiable, Codable, Hashable {
    public var id: String
    public var deliveryId: String
    public var birthday: Date
    public var height: Double
    public var weight: Double
    public var nurseCatch: Bool
    public var sex: Sex
    
    // Convert the model to a dictionary for Firestore compatibility
    var dictionary: [String: Any] {
        return [
            "id": id,
            "birthday": birthday.timeIntervalSince1970,
            "height": height,
            "weight": weight,
            "sex": sex.rawValue,
            "deliveryId": deliveryId
        ]
    }
    
    // Initialize from Firestore data dictionary
    public init?(from dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let deliveryId = dictionary["deliveryId"] as? String,
            let birthdayTimestamp = dictionary["birthday"] as? TimeInterval,
            let height = dictionary["height"] as? Double,
            let weight = dictionary["weight"] as? Double,
            let nurseCatch = dictionary["nurseCatch"] as? Bool,
            let sexRawValue = dictionary["sex"] as? String,
            let sex = Sex(rawValue: sexRawValue)
        else {
            return nil
        }
        
        self.id = id
        self.deliveryId = deliveryId
        self.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        self.height = height
        self.weight = weight
        self.nurseCatch = nurseCatch
        self.sex = sex
    }
    
    // Standard initializer
    public init(id: String, deliveryId: String, birthday: Date, height: Double, weight: Double, nurseCatch: Bool, sex: Sex
    ) {
        self.id = id
        self.deliveryId = deliveryId
        self.birthday = birthday
        self.height = height
        self.weight = weight
        self.nurseCatch = nurseCatch
        self.sex = sex
    }
    
    public init(deliveryId: String, nurseCatch: Bool, sex: Sex) {
        self.id = UUID().uuidString
        self.deliveryId = deliveryId
        self.birthday = Date()
        self.height = 3.3
        self.weight = 4.4
        self.nurseCatch = nurseCatch
        self.sex = sex
    }
}
