//
//  HospitalModel.swift
//
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

public struct Hospital: Identifiable, Codable, Hashable {
    public var id: String                       // Unique identifier for the hospital
    public var facility_name: String                     // Name of the hospital
    public var address: String                  // Hospital's street address
    public var citytown: String                     // City where the hospital is located
    public var state: String                    // State abbreviation (e.g., IN)
    public var zip_code: String                  // ZIP code of the hospital
    public var countyparish: String                   // County where the hospital is located
    public var telephone_number: String
    public var hospital_type: String                     // Type of hospital (e.g., Acute Care)
    public var hospital_ownership: String                // Ownership type of the hospital
    public var emergency_services: Bool          // Whether the hospital provides emergency services
    public var meets_criteria_for_birthing_friendly_designation: Bool           // Whether it meets the birthing-friendly criteria
    public var deliveryCount: Int               // Total deliveries recorded at the hospital
    public var babyCount: Int                   // Total babies born at the hospital

    // Init from dictionary
    var dictionary: [String: Any] {
        return [
            "id": id,
            "facility_name": facility_name,
            "address": address,
            "citytown": citytown,
            "state": state,
            "zip_code": zip_code,
            "countyparish": countyparish,
            "telephone_number": telephone_number,
            "hospital_type": hospital_type,
            "hospital_ownership": hospital_ownership,
            "emergency_services": emergency_services,
            "meets_criteria_for_birthing_friendly_designation": meets_criteria_for_birthing_friendly_designation,
            "deliveryCount": deliveryCount,
            "babyCount": babyCount
        ]
    }

    init?(from dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let facility_name = dictionary["facility_name"] as? String,
            let address = dictionary["address"] as? String,
            let citytown = dictionary["citytown"] as? String,
            let state = dictionary["state"] as? String,
            let zip_code = dictionary["zip_code"] as? String,
            let countyparish = dictionary["countyparish"] as? String,
            let telephone_number = dictionary["telephone_number"] as? String,
            let hospital_type = dictionary["hospital_type"] as? String,
            let hospital_ownership = dictionary["hospital_ownership"] as? String,
            let emergency_services = dictionary["emergency_services"] as? Bool,
            let meets_criteria_for_birthing_friendly_designation = dictionary["meets_criteria_for_birthing_friendly_designation"] as? Bool,
            let deliveryCount = dictionary["deliveryCount"] as? Int,
            let babyCount = dictionary["babyCount"] as? Int
        else {
            return nil
        }

        self.id = id
        self.facility_name = facility_name
        self.address = address
        self.citytown = citytown
        self.state = state
        self.zip_code = zip_code
        self.countyparish = countyparish
        self.telephone_number = telephone_number
        self.hospital_type = hospital_type
        self.hospital_ownership = hospital_ownership
        self.emergency_services = emergency_services
        self.meets_criteria_for_birthing_friendly_designation = meets_criteria_for_birthing_friendly_designation
        self.deliveryCount = deliveryCount
        self.babyCount = babyCount
    }

    public init(
        id: String,
        facility_name: String,
        address: String,
        citytown: String,
        state: String,
        zip_code: String,
        countyparish: String,
        telephone_number: String,
        hospital_type: String,
        hospital_ownership: String,
        emergency_services: Bool,
        meets_criteria_for_birthing_friendly_designation: Bool,
        deliveryCount: Int = 0,
        babyCount: Int = 0
    ) {
        self.id = id
        self.facility_name = facility_name
        self.address = address
        self.citytown = citytown
        self.state = state
        self.zip_code = zip_code
        self.countyparish = countyparish
        self.telephone_number = telephone_number
        self.hospital_type = hospital_type
        self.hospital_ownership = hospital_ownership
        self.emergency_services = emergency_services
        self.meets_criteria_for_birthing_friendly_designation = meets_criteria_for_birthing_friendly_designation
        self.deliveryCount = deliveryCount
        self.babyCount = babyCount
    }
}
