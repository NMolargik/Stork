//
//  HospitalRepositoryInterfaceTests.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 6/8/25.
//

import Foundation
import XCTest
@testable import StorkModel      // replace with the actual module name if different

// MARK: - Minimal in‑memory repository --------------------------------------

/// Lightweight, deterministic implementation of `HospitalRepositoryInterface`
/// so we can unit‑test repository behaviour without Firebase.
@MainActor
final class InMemoryHospitalRepository: HospitalRepositoryInterface {

    fileprivate var storage: [String: Hospital] = [:]

    // MARK: - CRUD ----------------------------------------------------------

    func createHospital(name: String) async throws -> Hospital {
        let hospital = Hospital.sampleHospital(id: UUID().uuidString, name: name)
        storage[hospital.id] = hospital
        return hospital
    }

    func updateHospitalStats(
        hospital: Hospital,
        additionalDeliveryCount: Int,
        additionalBabyCount: Int
    ) async throws -> Hospital {
        guard var existing = storage[hospital.id] else {
            throw HospitalError.notFound("")
        }
        existing.deliveryCount += additionalDeliveryCount
        existing.babyCount     += additionalBabyCount
        storage[existing.id]    = existing
        return existing
    }

    func getHospital(byId id: String) async throws -> Hospital {
        guard let hospital = storage[id] else {
            throw HospitalError.notFound("")
        }
        return hospital
    }

    func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital] {
        let hospitals = Array(storage.values)
        guard let partial = partialName, !partial.isEmpty else { return hospitals }
        return hospitals.filter {
            $0.facility_name.localizedCaseInsensitiveContains(partial)
        }
    }

    func getHospitals(state: String) async throws -> [Hospital] {
        let result = storage.values.filter { $0.state == state }
        if result.isEmpty { throw HospitalError.notFound("") }
        return result
    }

    func searchHospitals(byPartialName partialName: String) async throws -> [Hospital] {
        let matches = try await listHospitalsByPartialName(partialName: partialName)
        if matches.isEmpty { throw HospitalError.notFound("") }
        return matches
    }

    func deleteHospital(hospital: Hospital) async throws {
        guard storage.removeValue(forKey: hospital.id) != nil else {
            throw HospitalError.deletionFailed("")
        }
    }
}

// MARK: - Tests -------------------------------------------------------------

@MainActor
final class HospitalRepositoryInterfaceTests: XCTestCase {

    private var repo: InMemoryHospitalRepository!

    override func setUp() {
        super.setUp()
        repo = InMemoryHospitalRepository()
    }

    // 1. Create -------------------------------------------------------------

    func testCreateHospitalReturnsHospitalWithID() async throws {
        let created = try await repo.createHospital(name: "New Hope")
        XCTAssertFalse(created.id.isEmpty)
        XCTAssertEqual(created.facility_name, "New Hope")
    }

    // 2. Read ---------------------------------------------------------------

    func testGetHospitalByIDReturnsHospital() async throws {
        let hospital = try await repo.createHospital(name: "County General")
        let fetched  = try await repo.getHospital(byId: hospital.id)
        XCTAssertEqual(fetched, hospital)
    }

    func testGetHospitalThrowsWhenMissing() async {
        await assertThrows {
            _ = try await self.repo.getHospital(byId: "missing")
        }
    }

    // 3. Update -------------------------------------------------------------

    func testUpdateHospitalStatsChangesCounts() async throws {
        var hospital = try await repo.createHospital(name: "Stats Hosp")
        hospital = try await repo.updateHospitalStats(
            hospital: hospital,
            additionalDeliveryCount: 3,
            additionalBabyCount: 5
        )
        XCTAssertEqual(hospital.deliveryCount, 3)
        XCTAssertEqual(hospital.babyCount, 5)
    }

    // 4. List / search ------------------------------------------------------

    func testListHospitalsByPartialNameFilters() async throws {
        let a = try await repo.createHospital(name: "Kindred Hospital")
        _ = try await repo.createHospital(name: "General Hospital")

        let results = try await repo.listHospitalsByPartialName(partialName: "Kind")
        XCTAssertEqual(results, [a])
    }

    func testGetHospitalsByStateFilters() async throws {
        let indiana = Hospital.sampleHospital(state: "IN")
        let ohio    = Hospital.sampleHospital(state: "OH")
        // manually insert to storage
        repo.storage[indiana.id] = indiana
        repo.storage[ohio.id]    = ohio

        let results = try await repo.getHospitals(state: "IN")
        XCTAssertEqual(results.map(\.state), ["IN"])
    }

    // 5. Delete -------------------------------------------------------------

    func testDeleteHospitalRemovesHospital() async throws {
        let hospital = try await repo.createHospital(name: "Delete Me")
        try await repo.deleteHospital(hospital: hospital)

        await assertThrows {
            _ = try await self.repo.getHospital(byId: hospital.id)
        }
    }
}

// MARK: - Helpers -----------------------------------------------------------

/// Async variant of `XCTAssertThrowsError` without macros.
@discardableResult
private func assertThrows(
    _ expression: @escaping () async throws -> Void
) async -> Error? {
    do {
        try await expression()
        XCTFail("Expected error")
        return nil
    } catch {
        return error
    }
}

private extension Hospital {
    static func sampleHospital(
        id: String = UUID().uuidString,
        name: String = "Sample",
        deliveries: Int = 0,
        babies: Int = 0,
        state: String = "IN"
    ) -> Hospital {
        Hospital(
            id: id,
            facility_name: name,
            address: "123 Main St",
            citytown: "Fort Wayne",
            state: state,
            zip_code: "46802",
            countyparish: "Allen",
            telephone_number: "555-123-4567",
            hospital_type: "General",
            hospital_ownership: "Non-Profit",
            emergency_services: true,
            meets_criteria_for_birthing_friendly_designation: true,
            deliveryCount: deliveries,
            babyCount: babies
        )
    }
}
