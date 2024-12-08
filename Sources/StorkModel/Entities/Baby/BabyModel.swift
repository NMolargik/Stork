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
            "birthday": birthday.description,
            "height": height,
            "weight": weight,
            "sex": sex.rawValue,
            "deliveryId": deliveryId,
            "nurseCatch": nurseCatch
        ]
    }
    
    // Initialize from Firestore data dictionary
    public init?(from dictionary: [String: Any]) {
        print(dictionary.description)
        let isoFormatter = ISO8601DateFormatter()
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        guard
            let id = dictionary["id"] as? String,
            let deliveryId = dictionary["deliveryId"] as? String,
            let birthdayString = dictionary["birthday"] as? String,
            let height = dictionary["height"] as? Double,
            let weight = dictionary["weight"] as? Double,
            let nurseCatch = dictionary["nurseCatch"] as? Bool,
            let sexRawValue = dictionary["sex"] as? String,
            let sex = Sex(rawValue: sexRawValue)
        else {
            print("Missing or invalid required fields for baby")
            return nil
        }
        
        // Parse dates with fallback
        guard let birthday = isoFormatter.date(from: birthdayString) ??
                              fallbackFormatter.date(from: birthdayString)
        else {
            print("Invalid birthday format: \(birthdayString)")
            return nil
        }
        
        self.id = id
        self.deliveryId = deliveryId
        self.birthday = birthday
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
