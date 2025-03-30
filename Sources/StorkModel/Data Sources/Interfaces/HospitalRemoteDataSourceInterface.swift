//
//  HospitalRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation

/// A protocol defining the interface for remote data source interactions related to hospitals.
public protocol HospitalRemoteDataSourceInterface {
    /// Creates a new hospital record in Firestore and returns the newly created `Hospital`.
    ///
    /// - Parameter hospital: The `Hospital` object to create.
    /// - Returns: The newly created `Hospital`.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the creation operation fails due to a Firestore-related issue.
    func createHospital(hospital: Hospital) async throws -> Hospital

    /// Updates the hospital stats in Firestore by incrementing `deliveryCount` and `babyCount`.
    ///
    /// - Parameters:
    ///   - hospital: The `Hospital` object whose stats should be updated. Must include a valid Firestore `id`.
    ///   - additionalDeliveryCount: The number by which to increment `deliveryCount`.
    ///   - additionalBabyCount: The number by which to increment `babyCount`.
    /// - Returns: The updated `Hospital` object with local counts incremented.
    /// - Throws: `HospitalError.updateFailed` if the Firestore update operation fails.
    func updateHospitalStats(hospital: Hospital, additionalDeliveryCount: Int, additionalBabyCount: Int) async throws -> Hospital
    
    /// Fetches a single hospital record from Firestore by its unique ID, throwing an error if not found.
    ///
    /// - Parameter id: The unique ID of the hospital to fetch.
    /// - Returns: A `Hospital` object representing the fetched hospital.
    /// - Throws:
    ///   - `HospitalError.notFound`: If the hospital with the specified ID is not found.
    ///   - `HospitalError.firebaseError`: If the fetch operation fails due to a Firestore-related issue.
    func getHospital(byId id: String) async throws -> Hospital

    /// Lists all hospital records from Firestore, optionally filtered by partial name.
    ///
    /// - Parameter partialName: An optional substring to match hospital names. If `nil`, returns all hospitals.
    /// - Returns: An array of `Hospital` objects matching the specified filter (or an empty array if none match).
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital]

    /// Fetches hospitals located in a specific city and state.
    ///
    /// - Parameters:
    ///   - state: The state to filter hospitals.
    /// - Returns: An array of `Hospital` objects matching the given city and state (or an empty array if none match).
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the fetch operation fails due to a Firestore-related issue.
    func listHospitals(state: String) async throws -> [Hospital]

    /// Deletes a hospital record from Firestore.
    ///
    /// - Parameter id: The unique ID of the hospital to delete.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the deletion operation fails due to a Firestore-related issue.
    func deleteHospital(byId id: String) async throws
}
