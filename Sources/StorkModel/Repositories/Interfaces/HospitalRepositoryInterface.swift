//
//  HospitalRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the interface for domain-level hospital operations.
public protocol HospitalRepositoryInterface {
    /// Creates a new hospital record in Firestore. Requires admin intervention afterwards
    ///
    /// - Parameter name: The name of the new`Hospital` object to create.
    /// - Throws:
    ///   - `HospitalError.creationFailed`: If the operation fails to create the hospital.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func createHospital(name: String) async throws -> Hospital

    /// Updates the statistics of an existing hospital record in Firestore.
    ///
    /// - Parameter hospital: The `Hospital` object containing updated statistics.
    /// - Throws:
    ///   - `HospitalError.updateFailed`: If the operation fails to update the hospital.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func updateHospital(hospital: Hospital) async throws

    
    /// Fetches a single hospital by its unique ID.
    ///
    /// - Parameter id: The unique ID of the hospital to fetch.
    /// - Returns: A `Hospital` object representing the fetched hospital.
    /// - Throws:
    ///   - `HospitalError.notFound`: If the hospital with the specified ID is not found.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func getHospital(byId id: String) async throws -> Hospital

    /// Lists all hospitals or filters them based on an optional name.
    ///
    /// - Parameter name: An optional filter for the hospital name.
    /// - Returns: An array of `Hospital` objects matching the specified filters.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital]

    /// Fetches hospitals in a specific city and state.
    ///
    /// - Parameters:
    ///   - city: The city to filter hospitals by.
    ///   - state: The state to filter hospitals by.
    /// - Returns: An array of `Hospital` objects representing hospitals in the specified city and state.
    /// - Throws:
    ///   - `HospitalError.notFound`: If no hospitals are found in the specified city and state.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func getHospitals(byCity city: String, andState state: String) async throws -> [Hospital]

    /// Searches for hospitals by a partial name match.
    ///
    /// - Parameter partialName: The partial string to match against hospital names.
    /// - Returns: An array of `Hospital` objects with names matching the partial string.
    /// - Throws:
    ///   - `HospitalError.notFound`: If no hospitals are found matching the partial name.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func searchHospitals(byPartialName partialName: String) async throws -> [Hospital]
    
    /// Updates a hospital record's baby count whenever new deliveries are associated with it
    ///
    /// - Parameter hospital: The hospital record
    /// - Parameter babyCount: The total of new babies to add
    
    func updateAfterDelivery(hospital: Hospital, babyCount: Int) async throws -> Hospital
    
    /// Deletes an existing hospital record from Firestore.
    ///
    /// - Parameter hospital: The `Hospital` object to delete.
    /// - Throws:
    ///   - `HospitalError.deletionFailed`: If the operation fails to delete the hospital.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func deleteHospital(hospital: Hospital) async throws

}
