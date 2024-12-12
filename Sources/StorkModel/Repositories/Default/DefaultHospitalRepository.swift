//
//  DefaultHospitalRepository.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

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

    // MARK: - Methods

    /// Fetches a single hospital by its unique ID.
    public func getHospital(byId id: String) async throws -> Hospital {
        do {
            return try await remoteDataSource.getHospital(byId: id)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to fetch hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Lists hospitals based on optional filter criteria.
    public func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital] {
        do {
            return try await remoteDataSource.listHospitalsByPartialName(partialName: partialName)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to list hospitals: \(error.localizedDescription)")
        }
    }

    /// Creates a new hospital record.
    public func createHospital(_ name: String) async throws -> Hospital {
        do {
            return try await remoteDataSource.createHospital(Hospital(id: UUID().description, facility_name: name, address: "", citytown: "", state: "", zip_code: "", countyparish: "", telephone_number: "", hospital_type: "", hospital_ownership: "", emergency_services: false, meets_criteria_for_birthing_friendly_designation: false, deliveryCount: 0, babyCount: 0))
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.creationFailed("Failed to create hospital: \(error.localizedDescription)")
        }
    }

    /// Updates an existing hospital record.
    public func updateHospital(_ hospital: Hospital) async throws {
        do {
            try await remoteDataSource.updateHospitalStats(hospital)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.updateFailed("Failed to update hospital: \(error.localizedDescription)")
        }
    }

    /// Deletes an existing hospital record.
    public func deleteHospital(_ hospital: Hospital) async throws {
        do {
            try await remoteDataSource.deleteHospital(byId: hospital.id)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.deletionFailed("Failed to delete hospital: \(error.localizedDescription)")
        }
    }

    /// Fetches hospitals located in a given city and state.
    ///
    /// - Parameters:
    ///   - city: The city to filter hospitals.
    ///   - state: The state to filter hospitals.
    /// - Returns: A list of `Hospital` objects matching the given city and state.
    /// - Throws:
    ///   - `HospitalError.notFound`: If no hospitals are found.
    ///   - `HospitalError.firebaseError`: If the fetch operation fails due to a Firestore-related issue.
    ///   - `HospitalError.unknown`: If any other error occurs.
    public func getHospitals(byCity city: String, andState state: String) async throws -> [Hospital] {
        do {
            return try await remoteDataSource.listHospitals(city: city, state: state)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to fetch hospitals in \(city), \(state): \(error.localizedDescription)")
        }
    }

    /// Searches for hospitals by a partial name match.
    ///
    /// - Parameter partialName: The partial string to match against hospital names.
    /// - Returns: A list of `Hospital` objects with names matching the partial string.
    /// - Throws:
    ///   - `HospitalError.notFound`: If no hospitals are found.
    ///   - `HospitalError.firebaseError`: If the fetch operation fails due to a Firestore-related issue.
    ///   - `HospitalError.unknown`: If any other error occurs.
    public func searchHospitals(byPartialName partialName: String) async throws -> [Hospital] {
        do {
            return try await remoteDataSource.listHospitalsByPartialName(partialName: partialName)
        } catch let error as HospitalError {
            throw error
        } catch {
            throw HospitalError.unknown("Failed to search hospitals by name \(partialName): \(error.localizedDescription)")
        }
    }
    
    public func updateAfterDelivery(_ hospital: Hospital, babyCount: Int) async throws -> Hospital {
        var updatedHospital = hospital
        updatedHospital.deliveryCount += 1
        updatedHospital.babyCount += babyCount
        
        try await self.updateHospital(updatedHospital)
        return updatedHospital
    }
}
