//
//  HospitalRemoteDataSourceInterface.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// A protocol defining the interface for remote data source interactions related to hospitals.
public protocol HospitalRemoteDataSourceInterface {
    /// Creates a new hospital record in Firestore.
    ///
    /// This method adds a new hospital record to Firestore. The `id` field will be used as the document ID.
    ///
    /// - Parameter hospital: The `Hospital` object to create.
    /// - Returns: A `Hospital` record for for local append
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the creation operation fails due to a Firestore-related issue.
    func createHospital(hospital: Hospital) async throws -> Hospital
    
    /// Updates statistical data for a specific hospital in Firestore.
    ///
    /// This method is used to update the `deliveryCount` and `babyCount` fields for a hospital.
    ///
    /// - Parameter hospital: The `Hospital` object containing updated statistical data.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the update operation fails due to a Firestore-related issue.
    func updateHospitalStats(hospital: Hospital) async throws

    /// Fetches a single hospital record from Firestore by its unique ID.
    ///
    /// - Parameter id: The unique ID of the hospital to fetch.
    /// - Returns: A `Hospital` object representing the fetched hospital.
    /// - Throws:
    ///   - `HospitalError.notFound`: If the hospital with the specified ID is not found.
    ///   - `HospitalError.firebaseError`: If the fetch operation fails due to a Firestore-related issue.
    ///
    func getHospital(byId id: String) async throws -> Hospital

    /// Lists all hospital records from Firestore, optionally filtered by name.
    ///
    /// - Parameter name: An optional filter for the hospital name. If `nil`, returns all hospitals.
    /// - Returns: An array of `Hospital` objects matching the specified filter.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the operation fails due to a Firestore-related issue.
    func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital]

    /// Fetches hospitals located in a specific city and state.
    ///
    /// - Parameters:
    ///   - city: The city to filter hospitals.
    ///   - state: The state to filter hospitals.
    /// - Returns: A list of `Hospital` objects matching the given city and state.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the fetch operation fails due to a Firestore-related issue.
    func listHospitals(city: String, state: String) async throws -> [Hospital]

    /// Increments the delivery count for a specific hospital.
    ///
    /// This method increases the `deliveryCount` for a hospital record in Firestore.
    ///
    /// - Parameter id: The unique ID of the hospital to update.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the update operation fails due to a Firestore-related issue.
    func incrementDeliveryCount(forHospitalId id: String) async throws

    /// Increments the baby count for a specific hospital.
    ///
    /// This method increases the `babyCount` for a hospital record in Firestore.
    ///
    /// - Parameter id: The unique ID of the hospital to update.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the update operation fails due to a Firestore-related issue.
    func incrementBabyCount(babyCount: Int, forHospitalId id: String) async throws
    
    /// Deletes a hospital record from Firestore.
    ///
    /// This method removes a hospital record from Firestore using the specified `id`.
    ///
    /// - Parameter id: The unique ID of the hospital to delete.
    /// - Throws:
    ///   - `HospitalError.firebaseError`: If the deletion operation fails due to a Firestore-related issue.
    func deleteHospital(byId id: String) async throws
}
