//
//  HospitalRepositoryInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the interface for domain-level hospital operations.
public protocol HospitalRepositoryInterface {
    
    /// Creates a new hospital record in Firestore.
    ///
    /// - Parameter name: The name of the new `Hospital` object to create.
    /// - Returns: The newly created `Hospital`, including any assigned document ID.
    /// - Throws:
    ///   - `HospitalError.creationFailed`: If the operation fails to create the hospital.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func createHospital(name: String) async throws -> Hospital

    /// Updates hospital statistics in Firestore (e.g., incrementing baby/delivery counts).
    ///
    /// - Parameters:
    ///   - hospital: The `Hospital` object whose stats should be updated (must include a valid Firestore `id`).
    ///   - additionalDeliveryCount: The amount by which to increment the delivery count.
    ///   - additionalBabyCount: The amount by which to increment the baby count.
    /// - Returns: The updated `Hospital`, reflecting the new counts.
    /// - Throws:
    ///   - `HospitalError.updateFailed`: If the operation fails to update the hospital stats.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func updateHospitalStats(
        hospital: Hospital,
        additionalDeliveryCount: Int,
        additionalBabyCount: Int
    ) async throws -> Hospital

    /// Fetches a single hospital by its unique ID.
    ///
    /// - Parameter id: The unique ID of the hospital to fetch.
    /// - Returns: A `Hospital` object representing the fetched hospital.
    /// - Throws:
    ///   - `HospitalError.notFound`: If the hospital with the specified ID is not found.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func getHospital(byId id: String) async throws -> Hospital

    /// Lists all hospitals or filters them based on an optional partial name.
    ///
    /// - Parameter partialName: An optional substring to match against hospital names.
    /// - Returns: An array of `Hospital` objects matching the specified filter (or all if `partialName` is `nil`).
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
    
    /// Deletes an existing hospital record from Firestore.
    ///
    /// - Parameter hospital: The `Hospital` object to delete.
    /// - Throws:
    ///   - `HospitalError.deletionFailed`: If the operation fails to delete the hospital.
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func deleteHospital(hospital: Hospital) async throws
}
