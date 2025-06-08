//
//  DefaultHospitalRepository.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import SkipFoundation
import Foundation

/// A concrete implementation of the `HospitalRepositoryInterface` protocol.
/// Handles hospital-related operations by interacting with a remote data source.
public class DefaultHospitalRepository: HospitalRepositoryInterface {
    // MARK: - Properties

    /// The remote data source used to perform hospital operations.
    private let remoteDataSource: HospitalRemoteDataSourceInterface

    // MARK: - Initializer

    /// Initializes the `DefaultHospitalRepository` with a specified remote data source.
    ///
    /// - Parameter remoteDataSource: The remote data source implementing `HospitalRemoteDataSourceInterface`.
    public init(remoteDataSource: HospitalRemoteDataSourceInterface) {
        self.remoteDataSource = remoteDataSource
    }

    // MARK: - Create

    /// Creates a new hospital record in Firestore.
    ///
    /// - Parameter name: The name of the new `Hospital`.
    /// - Returns: The newly created `Hospital`, including its Firestore-generated `id`.
    /// - Throws: `HospitalError.creationFailed`, or other domain-specific errors on failure.
    public func createHospital(name: String) async throws -> Hospital {
        do {
            // Build an initial Hospital model with default fields
            let hospital = Hospital(
                id: UUID().uuidString,
                facility_name: name.uppercased(),
                address: "",
                citytown: "",
                state: "",
                zip_code: "",
                countyparish: "",
                telephone_number: "",
                hospital_type: "MISSING",
                hospital_ownership: "",
                emergency_services: false,
                meets_criteria_for_birthing_friendly_designation: true,
                deliveryCount: 0,
                babyCount: 0
            )

            // Call the remote data source to create it
            let createdHospital = try await remoteDataSource.createHospital(hospital: hospital)
            
            return createdHospital
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.creationFailed("Failed to create hospital: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Stats

    /// Updates hospital statistics in Firestore (e.g., incrementing `deliveryCount` and `babyCount`).
    ///
    /// - Parameters:
    ///   - hospital: The `Hospital` object whose stats are being updated.
    ///   - additionalDeliveryCount: How many deliveries to add.
    ///   - additionalBabyCount: How many babies to add.
    /// - Returns: The updated `Hospital`, reflecting the new counts.
    /// - Throws: `HospitalError.updateFailed`, or other errors if the update fails.
    public func updateHospitalStats(
        hospital: Hospital,
        additionalDeliveryCount: Int,
        additionalBabyCount: Int
    ) async throws -> Hospital {
        do {
            let updatedHospital = try await remoteDataSource.updateHospitalStats(
                hospital: hospital,
                additionalDeliveryCount: additionalDeliveryCount,
                additionalBabyCount: additionalBabyCount
            )
            return updatedHospital
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.updateFailed("Failed to update hospital stats: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch (Single)

    /// Fetches a single hospital by its unique ID.
    ///
    /// - Parameter id: The unique ID of the hospital to fetch.
    /// - Returns: A `Hospital` object for the specified ID.
    /// - Throws:
    ///   - `HospitalError.notFound`: If no hospital with the specified ID exists.
    ///   - `HospitalError.firebaseError`: If Firestore fails.
    ///   - `HospitalError.unknown`: For other unexpected errors.
    public func getHospital(byId id: String) async throws -> Hospital {
        do {
            return try await remoteDataSource.getHospital(byId: id)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to fetch hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - List / Search

    /// Lists hospitals based on an optional partial name.
    ///
    /// - Parameter partialName: An optional substring to match against hospital names.
    /// - Returns: A list of matching `Hospital` objects.
    /// - Throws: `HospitalError.firebaseError` or `HospitalError.unknown` if the operation fails.
    public func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital] {
        do {
            return try await remoteDataSource.listHospitalsByPartialName(partialName: partialName)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to list hospitals: \(error.localizedDescription)")
        }
    }

    /// Fetches hospitals located in a specific city and state.
    ///
    /// - Parameters:
    ///   - state: The state to filter hospitals by.
    /// - Returns: A list of `Hospital` objects matching the city and state.
    /// - Throws:
    ///   - `HospitalError.notFound`: If no hospitals are found.
    ///   - `HospitalError.firebaseError`: If Firestore fails.
    ///   - `HospitalError.unknown`: For any other error.
    public func getHospitals(state: String) async throws -> [Hospital] {
        do {
            return try await remoteDataSource.listHospitals(state: state)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to fetch hospitals in \(state): \(error.localizedDescription)")
        }
    }

    /// Searches for hospitals by a partial name match.
    ///
    /// - Parameter partialName: The partial string to match against hospital names.
    /// - Returns: A list of `Hospital` objects with matching names.
    /// - Throws:
    ///   - `HospitalError.notFound`: If none are found.
    ///   - `HospitalError.firebaseError`: If Firestore fails.
    ///   - `HospitalError.unknown`: For other unexpected errors.
    public func searchHospitals(byPartialName partialName: String) async throws -> [Hospital] {
        do {
            return try await remoteDataSource.listHospitalsByPartialName(partialName: partialName)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to search hospitals by name \(partialName): \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    /// Deletes an existing hospital record.
    ///
    /// - Parameter hospital: The `Hospital` object to delete.
    /// - Throws:
    ///   - `HospitalError.deletionFailed`: If Firestore deletion fails.
    ///   - `HospitalError`: For other domain-specific errors.
    public func deleteHospital(hospital: Hospital) async throws {
        do {
            try await remoteDataSource.deleteHospital(byId: hospital.id)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.deletionFailed("Failed to delete hospital: \(error.localizedDescription)")
        }
    }
}
