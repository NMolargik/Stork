//
//  HospitalModel.swift
//
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

public struct Hospital: Identifiable, Codable, Hashable {
    public var id: String
    public var facility_name: String // Formatted hospital name
    public var address: String // Formatted address
    public var citytown: String // Formatted city/town
    public var state: String // Formatted state abbreviation
    public var zip_code: String
    public var countyparish: String
    public var telephone_number: String
    public var hospital_type: String
    public var hospital_ownership: String
    public var emergency_services: Bool
    public var meets_criteria_for_birthing_friendly_designation: Bool
    public var deliveryCount: Int
    public var babyCount: Int

    // MARK: - Formatting Functions

    /// Formats a string to lowercase with each word capitalized.
    private static func formatTitleCase(_ text: String) -> String {
        return text
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    /// Formats an address while preserving numbers.
    private static func formatAddress(_ address: String) -> String {
        return address
            .split(separator: " ")
            .map { word in
                if Double(word) != nil {
                    return String(word)
                } else {
                    return word.prefix(1).uppercased() + word.dropFirst().lowercased()
                }
            }
            .joined(separator: " ")
    }

    /// Formats state as uppercase (e.g., "IN", "NY", "CA").
    private static func formatState(_ state: String) -> String {
        return state.uppercased()
    }

    // MARK: - Initializers

    init?(from dictionary: [String: Any], id: String?) {
        guard
            let id = id,
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
        self.facility_name = Hospital.formatTitleCase(facility_name)
        self.address = Hospital.formatAddress(address)
        self.citytown = Hospital.formatTitleCase(citytown)
        self.state = Hospital.formatState(state)
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
        self.facility_name = Hospital.formatTitleCase(facility_name)
        self.address = Hospital.formatAddress(address)
        self.citytown = Hospital.formatTitleCase(citytown)
        self.state = Hospital.formatState(state)
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
    // MARK: - Sample Data
    
    public static func sampleHospital() -> Hospital {
        return Hospital(
            id: UUID().uuidString,
            facility_name: "Sample Medical Center",
            address: "123 Main Street",
            citytown: "Springfield",
            state: "CA",
            zip_code: "90210",
            countyparish: "Los Angeles",
            telephone_number: "555-123-4567",
            hospital_type: "General Acute Care",
            hospital_ownership: "Non-Profit",
            emergency_services: true,
            meets_criteria_for_birthing_friendly_designation: true,
            deliveryCount: 150,
            babyCount: 300
        )
    }
}
