//
//  HospitalModel.swift
//
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

public struct Hospital: Identifiable, Codable, Hashable {
    public var id: String                       // Unique identifier for the hospital
    var name: String                     // Name of the hospital
    var address: String                  // Hospital's street address
    var city: String                     // City where the hospital is located
    var state: String                    // State abbreviation (e.g., IN)
    var zipCode: String                  // ZIP code of the hospital
    var county: String                   // County where the hospital is located
    var phone: String?                   // Optional phone number of the hospital
    var type: String                     // Type of hospital (e.g., Acute Care)
    var ownership: String                // Ownership type of the hospital
    var emergencyServices: Bool          // Whether the hospital provides emergency services
    var birthingFriendly: Bool           // Whether it meets the birthing-friendly criteria
    var deliveryCount: Int               // Total deliveries recorded at the hospital
    var babyCount: Int                   // Total babies born at the hospital

    // Init from dictionary
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "address": address,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "county": county,
            "phone": phone ?? "",
            "type": type,
            "ownership": ownership,
            "emergencyServices": emergencyServices,
            "birthingFriendly": birthingFriendly,
            "deliveryCount": deliveryCount,
            "babyCount": babyCount
        ]
    }

    init?(from dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let name = dictionary["name"] as? String,
            let address = dictionary["address"] as? String,
            let city = dictionary["city"] as? String,
            let state = dictionary["state"] as? String,
            let zipCode = dictionary["zipCode"] as? String,
            let county = dictionary["county"] as? String,
            let type = dictionary["type"] as? String,
            let ownership = dictionary["ownership"] as? String,
            let emergencyServices = dictionary["emergencyServices"] as? Bool,
            let birthingFriendly = dictionary["birthingFriendly"] as? Bool,
            let deliveryCount = dictionary["deliveryCount"] as? Int,
            let babyCount = dictionary["babyCount"] as? Int
        else {
            return nil
        }

        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.county = county
        self.phone = dictionary["phone"] as? String
        self.type = type
        self.ownership = ownership
        self.emergencyServices = emergencyServices
        self.birthingFriendly = birthingFriendly
        self.deliveryCount = deliveryCount
        self.babyCount = babyCount
    }

    init(
        id: String,
        name: String,
        address: String,
        city: String,
        state: String,
        zipCode: String,
        county: String,
        phone: String? = nil,
        type: String,
        ownership: String,
        emergencyServices: Bool,
        birthingFriendly: Bool,
        deliveryCount: Int = 0,
        babyCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.county = county
        self.phone = phone
        self.type = type
        self.ownership = ownership
        self.emergencyServices = emergencyServices
        self.birthingFriendly = birthingFriendly
        self.deliveryCount = deliveryCount
        self.babyCount = babyCount
    }
}
