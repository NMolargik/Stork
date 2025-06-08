//
//  HospitalRemoteDataSourceInterfaceTests.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 6/8/25.
//


import XCTest
@testable import StorkModel       // Replace if your module’s name differs

// MARK: - In‑memory fake ----------------------------------------------------

/// A lightweight, deterministic implementation of `HospitalRemoteDataSourceInterface`
/// that stores hospitals in a local dictionary so we can unit‑test behaviour
/// without touching Firestore.
final class InMemoryHospitalRemoteDataSource: HospitalRemoteDataSourceInterface {

    private var storage: [String: Hospital] = [:]

    func createHospital(hospital: Hospital) async throws -> Hospital {
        storage[hospital.id] = hospital
        return hospital
    }

    func updateHospitalStats(
        hospital: Hospital,
        additionalDeliveryCount: Int,
        additionalBabyCount: Int
    ) async throws -> Hospital {
        guard var stored = storage[hospital.id] else {
            throw HospitalError.notFound("")
        }
        stored.deliveryCount += additionalDeliveryCount
        stored.babyCount     += additionalBabyCount
        storage[hospital.id]  = stored
        return stored
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
        return hospitals.filter { $0.facility_name.localizedCaseInsensitiveContains(partial) }
    }

    func listHospitals(state: String) async throws -> [Hospital] {
        storage.values.filter { $0.state == state }
    }

    func deleteHospital(byId id: String) async throws {
        guard storage.removeValue(forKey: id) != nil else {
            throw HospitalError.notFound("")
        }
    }
}

// MARK: - XCTest helpers ----------------------------------------------------

/// Asynchronous variant of `XCTAssertThrowsError` that works without
/// default macro parameters (`#file`, `#line`), which Skip cannot transpile.
@discardableResult
func XCTAssertThrowsErrorAsync(
    _ expression: @escaping () async throws -> Void
) async -> Error? {
    do {
        try await expression()
        XCTFail("Expected error was not thrown")
        return nil
    } catch {
        // Success: an error was thrown
        return error
    }
}

// MARK: - Tests -------------------------------------------------------------

@MainActor
final class HospitalRemoteDataSourceInterfaceTests: XCTestCase {

    private var dataSource: InMemoryHospitalRemoteDataSource!

    override func setUp() {
        super.setUp()
        dataSource = InMemoryHospitalRemoteDataSource()
    }

    override func tearDown() {
        dataSource = nil
        super.tearDown()
    }

    // 1. Create ----------------------------------------------------------------

    func testCreateHospitalAddsHospital() async throws {
        let hospital = Hospital.sampleHospital()
        let created  = try await dataSource.createHospital(hospital: hospital)

        XCTAssertEqual(created, hospital)
        let all = try await dataSource.listHospitalsByPartialName(partialName: nil)
        XCTAssertEqual(all.count, 1)
    }

    // 2. Read ------------------------------------------------------------------

    func testGetHospitalReturnsHospital() async throws {
        let hospital = Hospital.sampleHospital()
        _ = try await dataSource.createHospital(hospital: hospital)

        let fetched = try await dataSource.getHospital(byId: hospital.id)
        XCTAssertEqual(fetched, hospital)
    }

    func testGetHospitalThrowsForMissingId() async {
        let err = await XCTAssertThrowsErrorAsync {
            _ = try await self.dataSource.getHospital(byId: "missing-id")
        }
        XCTAssertTrue(err is HospitalError)
    }

    // 3. Update ---------------------------------------------------------------

    func testUpdateHospitalStatsIncrementsCounts() async throws {
        var hospital = Hospital.sampleHospital(deliveries: 3, babies: 5)
        hospital = try await dataSource.createHospital(hospital: hospital)

        let updated = try await dataSource.updateHospitalStats(
            hospital: hospital,
            additionalDeliveryCount: 2,
            additionalBabyCount: 4
        )

        XCTAssertEqual(updated.deliveryCount, 5)
        XCTAssertEqual(updated.babyCount, 9)
    }

    // 4. List / filter --------------------------------------------------------

    func testListHospitalsByPartialNameFiltersCorrectly() async throws {
        let a = Hospital.sampleHospital(name: "Kindred Hospital")
        let b = Hospital.sampleHospital(name: "General Hospital")
        _ = try await dataSource.createHospital(hospital: a)
        _ = try await dataSource.createHospital(hospital: b)

        let filtered = try await dataSource.listHospitalsByPartialName(partialName: "Kind")
        XCTAssertEqual(filtered, [a])
    }

    func testListHospitalsByStateFiltersCorrectly() async throws {
        let indiana = Hospital.sampleHospital(state: "IN")
        let ohio    = Hospital.sampleHospital(state: "OH")
        _ = try await dataSource.createHospital(hospital: indiana)
        _ = try await dataSource.createHospital(hospital: ohio)

        let result = try await dataSource.listHospitals(state: "IN")
        XCTAssertEqual(result, [indiana])
    }

    // 5. Delete --------------------------------------------------------------

    func testDeleteHospitalRemovesHospital() async throws {
        let hospital = Hospital.sampleHospital()
        _ = try await dataSource.createHospital(hospital: hospital)

        try await dataSource.deleteHospital(byId: hospital.id)

        await XCTAssertThrowsErrorAsync {
            _ = try await self.dataSource.getHospital(byId: hospital.id)
        }
    }
}

// MARK: - Sample helpers -----------------------------------------------------

private extension Hospital {
    static func sampleHospital(
        id: String = UUID().uuidString,
        name: String = "Sample Medical Center",
        deliveries: Int = 0,
        babies: Int = 0,
        state: String = "IN"
    ) -> Hospital {
        Hospital(
            id: id,
            facility_name: name,
            address: "123 Main Street",
            citytown: "Fort Wayne",
            state: state,
            zip_code: "46802",
            countyparish: "Allen",
            telephone_number: "555‑123‑4567",
            hospital_type: "General",
            hospital_ownership: "Non‑Profit",
            emergency_services: true,
            meets_criteria_for_birthing_friendly_designation: true,
            deliveryCount: deliveries,
            babyCount: babies
        )
    }
}
