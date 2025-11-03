// Hospital.swift
// Stork
//
// Created by Nick Molargik on 9/28/25.
//

import Foundation

struct Hospital: Codable, Identifiable, Hashable {
    var remoteId: String
    var id: String { remoteId }
    
    var facilityName: String
    var address: String
    var citytown: String
    var state: String
    var zipCode: String
    var countyparish: String
    var telephoneNumber: String
    var hospitalType: String
    var hospitalOwnership: String
    var emergencyServices: Bool
    var meetsCriteriaForBirthingFriendlyDesignation: Bool
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case remoteId = "id"
        case facilityName = "facility_name"
        case address
        case citytown
        case state
        case zipCode = "zip_code"
        case countyparish
        case telephoneNumber = "telephone_number"
        case hospitalType = "hospital_type"
        case hospitalOwnership = "hospital_ownership"
        case emergencyServices = "emergency_services"
        case meetsCriteriaForBirthingFriendlyDesignation = "meets_criteria_for_birthing_friendly_designation"
        // Note: id is not decoded; generated locally
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.remoteId = try container.decode(String.self, forKey: .remoteId)
        self.facilityName = Hospital.formatTitleCase(try container.decode(String.self, forKey: .facilityName))
        self.address = Hospital.formatAddress(try container.decode(String.self, forKey: .address))
        self.citytown = Hospital.formatTitleCase(try container.decode(String.self, forKey: .citytown))
        self.state = Hospital.formatState(try container.decode(String.self, forKey: .state))
        self.zipCode = try container.decode(String.self, forKey: .zipCode)
        self.countyparish = try container.decode(String.self, forKey: .countyparish)
        self.telephoneNumber = try container.decode(String.self, forKey: .telephoneNumber)
        self.hospitalType = try container.decode(String.self, forKey: .hospitalType)
        self.hospitalOwnership = try container.decode(String.self, forKey: .hospitalOwnership)
        self.emergencyServices = try container.decode(Bool.self, forKey: .emergencyServices)
        self.meetsCriteriaForBirthingFriendlyDesignation = try container.decode(Bool.self, forKey: .meetsCriteriaForBirthingFriendlyDesignation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(remoteId, forKey: .remoteId)
        try container.encode(facilityName, forKey: .facilityName)
        try container.encode(address, forKey: .address)
        try container.encode(citytown, forKey: .citytown)
        try container.encode(state, forKey: .state)
        try container.encode(zipCode, forKey: .zipCode)
        try container.encode(countyparish, forKey: .countyparish)
        try container.encode(telephoneNumber, forKey: .telephoneNumber)
        try container.encode(hospitalType, forKey: .hospitalType)
        try container.encode(hospitalOwnership, forKey: .hospitalOwnership)
        try container.encode(emergencyServices, forKey: .emergencyServices)
        try container.encode(meetsCriteriaForBirthingFriendlyDesignation, forKey: .meetsCriteriaForBirthingFriendlyDesignation)
    }
    
    // MARK: - Formatting Methods
    private static func formatTitleCase(_ text: String) -> String {
        return text
            .lowercased()
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
    
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
    
    private static func formatState(_ state: String) -> String {
        return state.uppercased()
    }
    
    init(
        remoteId: String = "",
        facilityName: String = "",
        address: String = "",
        citytown: String = "",
        state: String = "",
        zipCode: String = "",
        countyparish: String = "",
        telephoneNumber: String = "",
        hospitalType: String = "",
        hospitalOwnership: String = "",
        emergencyServices: Bool = false,
        meetsCriteriaForBirthingFriendlyDesignation: Bool = false
    ) {
        self.remoteId = remoteId
        self.facilityName = Hospital.formatTitleCase(facilityName)
        self.address = Hospital.formatAddress(address)
        self.citytown = Hospital.formatTitleCase(citytown)
        self.state = Hospital.formatState(state)
        self.zipCode = zipCode
        self.countyparish = countyparish
        self.telephoneNumber = telephoneNumber
        self.hospitalType = hospitalType
        self.hospitalOwnership = hospitalOwnership
        self.emergencyServices = emergencyServices
        self.meetsCriteriaForBirthingFriendlyDesignation = meetsCriteriaForBirthingFriendlyDesignation
    }
    
    static func sample() -> Hospital {
        return Hospital(
            remoteId: UUID().uuidString,
            facilityName: "Sample Medical Center",
            address: "123 Main Street",
            citytown: "Springfield",
            state: "CA",
            zipCode: "90210",
            countyparish: "Los Angeles",
            telephoneNumber: "555-123-4567",
            hospitalType: "General Acute Care",
            hospitalOwnership: "Non-Profit",
            emergencyServices: true,
            meetsCriteriaForBirthingFriendlyDesignation: true
        )
    }
}
