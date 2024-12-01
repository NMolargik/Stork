//
//  MockHospitalRepository.swift
//
//
//  Created by Nick Molargik on 11/20/24.
//

import Foundation
import SkipFoundation

/// A mock implementation of the `HospitalRepositoryInterface` protocol for testing purposes.
public class MockHospitalRepository: HospitalRepositoryInterface {
    // MARK: - Properties

    /// A list of mock hospitals used for in-memory storage.
    private var hospitals: [Hospital]

    // MARK: - Initializer

    /// Initializes the mock repository with optional sample data.
    ///
    /// - Parameter hospitals: An array of `Hospital` objects to initialize the repository with.
    ///   Defaults to a predefined set of mock hospitals.
    public init(hospitals: [Hospital] = []) {
        self.hospitals = hospitals.isEmpty ? Self.generateMockHospitals() : hospitals
    }

    // MARK: - Methods

    /// Fetches a single hospital by its unique ID.
    ///
    /// - Parameter id: The unique ID of the hospital.
    /// - Returns: A `Hospital` object matching the ID.
    /// - Throws: `HospitalError.notFound` if no hospital with the specified ID exists.
    public func getHospital(byId id: String) async throws -> Hospital {
        guard let hospital = hospitals.first(where: { $0.id == id }) else {
            throw HospitalError.notFound("Hospital with ID \(id) not found.")
        }
        return hospital
    }

    /// Lists hospitals based on an optional filter for hospital name.
    ///
    /// - Parameter name: An optional filter for the hospital name.
    /// - Returns: An array of `Hospital` objects matching the specified name filter.
    public func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital] {
        guard let name = partialName?.lowercased() else { return hospitals }
        return hospitals.filter { $0.facility_name.lowercased().contains(partialName ?? "") }
    }

    /// Lists hospitals filtered by city and state.
    ///
    /// - Parameters:
    ///   - city: The city to filter hospitals by.
    ///   - state: The state to filter hospitals by.
    /// - Returns: An array of `Hospital` objects matching the specified city and state.
    /// - Throws: `HospitalError.notFound` if no hospitals are found in the specified city and state.
    public func getHospitals(byCity city: String, andState state: String) async throws -> [Hospital] {
        let filteredHospitals = hospitals.filter {
            #if !SKIP
            $0.citytown.caseInsensitiveCompare(city) == ComparisonResult.orderedSame &&
            $0.state.caseInsensitiveCompare(state) == ComparisonResult.orderedSame
            #else
            $0.citytown.equals(city, ignoreCase = true) &&
            $0.state.equals(state, ignoreCase = true)
            #endif
        }
        guard !filteredHospitals.isEmpty else {
            print("damn")
            throw HospitalError.notFound("No hospitals found in \(city), \(state).")
        }
        return filteredHospitals
    }

    /// Searches for hospitals by a partial name match.
    ///
    /// - Parameter partialName: The partial string to match against hospital names.
    /// - Returns: A list of `Hospital` objects with names matching the partial string.
    /// - Throws: `HospitalError.notFound` if no hospitals are found.
    public func searchHospitals(byPartialName partialName: String) async throws -> [Hospital] {
        let filteredHospitals = hospitals.filter {
            #if !SKIP
            $0.facility_name.range(of: partialName, options: NSString.CompareOptions.caseInsensitive) != nil
            #else
            $0.facility_name.contains(partialName, ignoreCase = true)
            #endif
        }
        guard !filteredHospitals.isEmpty else {
            throw HospitalError.notFound("No hospitals found matching the name \(partialName).")
        }
        return filteredHospitals
    }

    /// Creates a new hospital record.
    ///
    /// - Parameter hospital: The `Hospital` object to create.
    /// - Throws: `HospitalError.creationFailed` if a hospital with the same ID already exists.
    public func createHospital(_ name: String) async throws {
        
        let hospital = Hospital(id: UUID().description, facility_name: name, address: "", citytown: "", state: "", zip_code: "", countyparish: "", telephone_number: "", hospital_type: "", hospital_ownership: "", emergency_services: false, meets_criteria_for_birthing_friendly_designation: false, deliveryCount: 0, babyCount: 0)
        if hospitals.contains(where: { $0.id == hospital.id }) {
            throw HospitalError.creationFailed("Hospital with ID \(hospital.id) already exists.")
        }
        hospitals.append(hospital)
    }

    /// Updates an existing hospital record.
    ///
    /// - Parameter hospital: The `Hospital` object containing updated data.
    /// - Throws: `HospitalError.notFound` if the hospital does not exist.
    public func updateHospital(_ hospital: Hospital) async throws {
        guard let index = hospitals.firstIndex(where: { $0.id == hospital.id }) else {
            throw HospitalError.notFound("Hospital with ID \(hospital.id) not found.")
        }
        hospitals[index] = hospital
    }

    /// Deletes an existing hospital record.
    ///
    /// - Parameter hospital: The `Hospital` object to delete.
    /// - Throws: `HospitalError.deletionFailed` if the hospital does not exist.
    public func deleteHospital(_ hospital: Hospital) async throws {
        guard let index = hospitals.firstIndex(where: { $0.id == hospital.id }) else {
            throw HospitalError.deletionFailed("Failed to delete hospital with ID \(hospital.id).")
        }
        hospitals.remove(at: index)
    }

    // MARK: - Mock Data Generator

    /// Generates a set of predefined mock hospitals.
    ///
    /// - Returns: An array of `Hospital` objects representing mock data.
    private static func generateMockHospitals() -> [Hospital] {
        return [
            Hospital(id: UUID().uuidString, facility_name: "Parkview Medical Center", address: "123 Health Ave", citytown: "Fort Wayne", state: "IN", zip_code: "46805", countyparish: "Allen", telephone_number: "123-456-7890", hospital_type: "Acute Care", hospital_ownership: "Private", emergency_services: true, meets_criteria_for_birthing_friendly_designation: true, deliveryCount: 50, babyCount: 100),
            Hospital(id: UUID().uuidString, facility_name: "Parkway Hospital", address: "456 Wellness St", citytown: "Indianapolis", state: "IN", zip_code: "46220", countyparish: "Marion", telephone_number: "987-654-3210", hospital_type: "Acute Care", hospital_ownership: "Government", emergency_services: true, meets_criteria_for_birthing_friendly_designation: false, deliveryCount: 30, babyCount: 60),
            Hospital(id: UUID().uuidString, facility_name: "Sunnyvale General", address: "789 Sunshine Blvd", citytown: "Fort Wayne", state: "IN", zip_code: "47408", countyparish: "Monroe", telephone_number: "555-123-4567", hospital_type: "General", hospital_ownership: "Private", emergency_services: false, meets_criteria_for_birthing_friendly_designation: true, deliveryCount: 20, babyCount: 40),
            Hospital(id: UUID().uuidString, facility_name: "Community Health Center", address: "321 Care Rd", citytown: "Muncie", state: "IN", zip_code: "47303", countyparish: "Delaware", telephone_number: "444-555-6666", hospital_type: "Community", hospital_ownership: "Non-Profit", emergency_services: true, meets_criteria_for_birthing_friendly_designation: false, deliveryCount: 10, babyCount: 20),
            Hospital(id: UUID().uuidString, facility_name: "Greenfield Regional Hospital", address: "654 Regional Dr", citytown: "Greenfield", state: "IN", zip_code: "46140", countyparish: "Hancock", telephone_number: "333-222-1111", hospital_type: "Regional", hospital_ownership: "Private", emergency_services: true, meets_criteria_for_birthing_friendly_designation: true, deliveryCount: 40, babyCount: 80),
            Hospital(id: UUID().uuidString, facility_name: "Springfield Medical", address: "987 Specialty Ln", citytown: "Evansville", state: "IN", zip_code: "47715", countyparish: "Vanderburgh", telephone_number: "999-888-7777", hospital_type: "Specialty", hospital_ownership: "Private", emergency_services: false, meets_criteria_for_birthing_friendly_designation: true, deliveryCount: 15, babyCount: 30)
        ]
    }
}
