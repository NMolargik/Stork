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
        return hospitals.filter { $0.name.lowercased().contains(partialName ?? "") }
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
            $0.city.caseInsensitiveCompare(city) == ComparisonResult.orderedSame &&
            $0.state.caseInsensitiveCompare(state) == ComparisonResult.orderedSame
            #else
            $0.city.equals(city, ignoreCase = true) &&
            $0.state.equals(state, ignoreCase = true)
            #endif
        }
        guard !filteredHospitals.isEmpty else {
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
            $0.name.range(of: partialName, options: NSString.CompareOptions.caseInsensitive) != nil
            #else
            $0.name.contains(partialName, ignoreCase = true)
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
        let hospital = Hospital(id: UUID().description, name: name, address: "", city: "", state: "", zipCode: "", county: "", phone: "", type: "", ownership: "", emergencyServices: false, birthingFriendly: false, deliveryCount: 0, babyCount: 0)
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
            Hospital(id: UUID().uuidString, name: "Parkview Medical Center", address: "123 Health Ave", city: "Fort Wayne", state: "IN", zipCode: "46805", county: "Allen", phone: "123-456-7890", type: "Acute Care", ownership: "Private", emergencyServices: true, birthingFriendly: true, deliveryCount: 50, babyCount: 100),
            Hospital(id: UUID().uuidString, name: "Parkway Hospital", address: "456 Wellness St", city: "Indianapolis", state: "IN", zipCode: "46220", county: "Marion", phone: "987-654-3210", type: "Acute Care", ownership: "Government", emergencyServices: true, birthingFriendly: false, deliveryCount: 30, babyCount: 60),
            Hospital(id: UUID().uuidString, name: "Sunnyvale General", address: "789 Sunshine Blvd", city: "Bloomington", state: "IN", zipCode: "47408", county: "Monroe", phone: "555-123-4567", type: "General", ownership: "Private", emergencyServices: false, birthingFriendly: true, deliveryCount: 20, babyCount: 40),
            Hospital(id: UUID().uuidString, name: "Community Health Center", address: "321 Care Rd", city: "Muncie", state: "IN", zipCode: "47303", county: "Delaware", phone: "444-555-6666", type: "Community", ownership: "Non-Profit", emergencyServices: true, birthingFriendly: false, deliveryCount: 10, babyCount: 20),
            Hospital(id: UUID().uuidString, name: "Greenfield Regional Hospital", address: "654 Regional Dr", city: "Greenfield", state: "IN", zipCode: "46140", county: "Hancock", phone: "333-222-1111", type: "Regional", ownership: "Private", emergencyServices: true, birthingFriendly: true, deliveryCount: 40, babyCount: 80),
            Hospital(id: UUID().uuidString, name: "Springfield Medical", address: "987 Specialty Ln", city: "Evansville", state: "IN", zipCode: "47715", county: "Vanderburgh", phone: "999-888-7777", type: "Specialty", ownership: "Private", emergencyServices: false, birthingFriendly: true, deliveryCount: 15, babyCount: 30)
        ]
    }
}
