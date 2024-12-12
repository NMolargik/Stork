//
//  FirebaseHospitalDatasource.swift
//
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation
#if SKIP
import SkipFirebaseFirestore
#else
import FirebaseFirestore
#endif

/// A concrete implementation of the `HospitalRemoteDataSourceInterface` protocol.
/// Handles interactions with Firebase Firestore for hospital data.
public class FirebaseHospitalDatasource: HospitalRemoteDataSourceInterface {
    
    // MARK: - Properties

    /// Firestore database instance for interacting with Firebase.
    private let db: Firestore

    // MARK: - Initializer

    /// Initializes the data source with a Firestore instance.
    public init() {
        self.db = Firestore.firestore()
    }

    // MARK: - Public Methods

    /// Updates hospital stats for an existing hospital in Firestore.
    public func updateHospitalStats(_ hospital: Hospital) async throws {
        do {
            let data: [String: Any] = [
                "deliveryCount": hospital.deliveryCount,
                "babyCount": hospital.babyCount
            ]
            try await db.collection("Hospital").document(hospital.id).setData(data, merge: true)
        } catch {
            throw HospitalError.updateFailed("Failed to update hospital stats: \(error.localizedDescription)")
        }
    }

    /// Creates a new hospital record in Firestore.
    public func createHospital(_ hospital: Hospital) async throws -> Hospital {
        do {
            let data: [String: Any] = [
                "facility_name": hospital.facility_name,
                "address": hospital.address,
                "citytown": hospital.citytown,
                "state": hospital.state,
                "zip_code": hospital.zip_code,
                "countyparish": hospital.countyparish,
                "telephone_number": hospital.telephone_number,
                "hospital_type": hospital.hospital_type,
                "hospital_ownership": hospital.hospital_ownership,
                "emergency_services": hospital.emergency_services,
                "meets_criteria_for_birthing_friendly_designation": hospital.meets_criteria_for_birthing_friendly_designation,
                "deliveryCount": hospital.deliveryCount,
                "babyCount": hospital.babyCount
            ]
            let reference = try await db.collection("Hospital").addDocument(data: data)
            var newHospital = hospital
            newHospital.id = reference.documentID
            return newHospital
        } catch {
            throw HospitalError.creationFailed("Failed to create hospital: \(error.localizedDescription)")
        }
    }

    /// Deletes a hospital from Firestore.
    public func deleteHospital(byId id: String) async throws {
        do {
            try await db.collection("Hospital").document(id).delete()
        } catch {
            throw HospitalError.deletionFailed("Failed to delete hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Fetches a hospital by its unique ID from Firestore.
    public func getHospital(byId id: String) async throws -> Hospital {
        do {
            let document = try await db.collection("hospitals").document(id).getDocument()
            guard let data = document.data() else {
                throw HospitalError.notFound("Hospital with ID \(id) not found.")
            }
            return try mapDocumentToHospital(data: data)
        } catch {
            throw HospitalError.notFound("Failed to fetch hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Fetches hospitals located in a specific city and state.
    public func listHospitals(city: String, state: String) async throws -> [Hospital] {
        do {
            // Automatically uppercase both city and state
            let uppercasedCity = city.uppercased()
            let uppercasedState = state.uppercased()
            
            let query = db.collection("Hospital")
                .whereField("citytown", isEqualTo: uppercasedCity)
                .whereField("state", isEqualTo: uppercasedState)
            let snapshot = try await query.getDocuments()
            
            return try snapshot.documents.map { document in
                try mapDocumentToHospital(data: document.data())
            }
        } catch {
            throw HospitalError.notFound("Failed to fetch hospitals in \(city), \(state): \(error.localizedDescription)")
        }
    }

    @MainActor
    /// Searches for hospitals by a partial name match.
    public func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital] {
        guard let partialName = partialName, !partialName.isEmpty else {
            throw HospitalError.notFound("Invalid search text")
        }

        // Normalize user input to uppercase to match Firestore data
        let normalizedPartialName = partialName.uppercased()

        do {
            let query = db.collection("Hospital")
                .whereField("facility_name", isGreaterThanOrEqualTo: normalizedPartialName)
                .whereField("facility_name", isLessThan: normalizedPartialName + "\u{F8FF}")
                .order(by: "facility_name")

            let snapshot = try await query.getDocuments()

            return try snapshot.documents.map { document in
                try mapDocumentToHospital(data: document.data())
            }
        } catch {
            print("Error occurred: \(error.localizedDescription)")
            throw HospitalError.notFound("Failed to search hospitals by name \(partialName): \(error.localizedDescription)")
        }
    }

    /// Increments the delivery count for a specific hospital.
    public func incrementDeliveryCount(forHospitalId id: String) async throws {
        do {
            try await db.collection("Hospital").document(id).updateData([
                "deliveryCount": FieldValue.increment(Int64(1))
            ])
        } catch {
            throw HospitalError.updateFailed("Failed to increment delivery count for hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Increments the baby count for a specific hospital.
    public func incrementBabyCount(babyCount: Int, forHospitalId id: String) async throws {
        do {
            try await db.collection("Hospital").document(id).updateData([
                "babyCount": FieldValue.increment(Int64(babyCount))
            ])
        } catch {
            throw HospitalError.updateFailed("Failed to increment baby count for hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods
    /// Maps Firestore document data to a `Hospital` object.
    private func mapDocumentToHospital(data: [String: Any]) throws -> Hospital {
        guard
            let id = data["id"] as? String,
            let facility_name = data["facility_name"] as? String,
            let address = data["address"] as? String,
            let citytown = data["citytown"] as? String,
            let state = data["state"] as? String,
            let zip_code = data["zip_code"] as? String,
            let countyparish = data["countyparish"] as? String,
            let telephone_number = data["telephone_number"] as? String,
            let hospital_type = data["hospital_type"] as? String,
            let hospital_ownership = data["hospital_ownership"] as? String,
            let emergency_services = data["emergency_services"] as? Bool,
            let meets_criteria_for_birthing_friendly_designation = data["meets_criteria_for_birthing_friendly_designation"] as? Bool,
            let deliveryCount = data["deliveryCount"] as? Int,
            let babyCount = data["babyCount"] as? Int
        else {
            print("mapping failed")
            throw HospitalError.unknown("Failed to map hospital data.")
        }
        return Hospital(
            id: id,
            facility_name: facility_name,
            address: address,
            citytown: citytown,
            state: state,
            zip_code: zip_code,
            countyparish: countyparish,
            telephone_number: telephone_number,
            hospital_type: hospital_type,
            hospital_ownership: hospital_ownership,
            emergency_services: emergency_services,
            meets_criteria_for_birthing_friendly_designation: meets_criteria_for_birthing_friendly_designation,
            deliveryCount: deliveryCount,
            babyCount: babyCount
        )
    }
}
