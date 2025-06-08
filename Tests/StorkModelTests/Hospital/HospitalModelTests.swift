//
//  HospitalModelTests.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 6/8/25.
//

import XCTest
@testable import StorkModel

@MainActor
final class HospitalModelTests: XCTestCase {

    // MARK: - Formatting helpers ------------------------------------------

    func testFormattingHelpers() {
        let raw = Hospital(
            id: "1",
            facility_name: "county general hospital",
            address: "456 elm AVE",
            citytown: "fort wayne",
            state: "in",
            zip_code: "46802",
            countyparish: "Allen",
            telephone_number: "555-987-6543",
            hospital_type: "General Acute Care",
            hospital_ownership: "Government",
            emergency_services: true,
            meets_criteria_for_birthing_friendly_designation: false
        )

        XCTAssertEqual(raw.facility_name, "County General Hospital")
        XCTAssertEqual(raw.address, "456 Elm Ave")
        XCTAssertEqual(raw.citytown, "Fort Wayne")
        XCTAssertEqual(raw.state, "IN")
    }

    // MARK: - Dictionary initialiser --------------------------------------

    func testDictionaryInitializerSucceeds() {
        let dict: [String: Any] = [
            "facility_name": "memorial hospital",
            "address": "123 main st",
            "citytown": "springfield",
            "state": "ca",
            "zip_code": "90210",
            "countyparish": "Los Angeles",
            "telephone_number": "555-123-4567",
            "hospital_type": "General Acute Care",
            "hospital_ownership": "Non-Profit",
            "emergency_services": true,
            "meets_criteria_for_birthing_friendly_designation": true,
            "deliveryCount": 10,
            "babyCount": 20
        ]

        let hospital = Hospital(from: dict, id: "abc123")
        XCTAssertNotNil(hospital)
        XCTAssertEqual(hospital?.id, "abc123")
        XCTAssertEqual(hospital?.facility_name, "Memorial Hospital")
    }

    func testDictionaryInitializerFails() {
        let dict: [String: Any] = [
            "facility_name": "bad hospital" // missing the rest of the required keys
        ]
        XCTAssertNil(Hospital(from: dict, id: "xyz"))
    }

    // MARK: - Codable round‑trip ------------------------------------------

    func testCodableRoundTrip() throws {
        let original = Hospital.sampleHospital()
        let data     = try JSONEncoder().encode(original)
        let decoded  = try JSONDecoder().decode(Hospital.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - Hashable / Equatable ----------------------------------------

    func testHashableAndEquatable() {
        let a = Hospital.sampleHospital()
        let b = a
        XCTAssertEqual(a, b)

        var set = Set<Hospital>()
        set.insert(a)
        XCTAssertTrue(set.contains(b))
    }
}
