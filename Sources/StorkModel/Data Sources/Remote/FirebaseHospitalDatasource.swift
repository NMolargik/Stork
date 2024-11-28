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
            try await db.collection("hospitals").document(hospital.id).setData(data, merge: true)
        } catch {
            throw HospitalError.firebaseError("Failed to update hospital stats: \(error.localizedDescription)")
        }
    }

    /// Creates a new hospital record in Firestore.
    public func createHospital(_ hospital: Hospital) async throws {
        do {
            let data: [String: Any] = [
                "id": hospital.id,
                "name": hospital.name,
                "address": hospital.address,
                "citytown": hospital.city,
                "state": hospital.state,
                "zip_code": hospital.zipCode,
                "countyparish": hospital.county,
                "telephone_number": hospital.phone ?? "",
                "hospital_type": hospital.type,
                "hospital_ownership": hospital.ownership,
                "emergency_services": hospital.emergencyServices,
                "meets_criteria_for_birthing_friendly_designation": hospital.birthingFriendly,
                "deliveryCount": hospital.deliveryCount,
                "babyCount": hospital.babyCount
            ]
            try await db.collection("hospitals").document(hospital.id).setData(data)
        } catch {
            throw HospitalError.firebaseError("Failed to create hospital: \(error.localizedDescription)")
        }
    }

    /// Deletes a hospital from Firestore.
    public func deleteHospital(byId id: String) async throws {
        do {
            try await db.collection("hospitals").document(id).delete()
        } catch {
            throw HospitalError.firebaseError("Failed to delete hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Fetches a hospital by its unique ID from Firestore.
    public func getHospital(byId id: String) async throws -> Hospital {
        do {
            let document = try await db.collection("hospitals").document(id).getDocument()
            guard let data = document.data() else {
                throw HospitalError.notFound("Hospital with ID \(id) not found.")
            }
            return try mapDocumentToHospital(id: id, data: data)
        } catch {
            throw HospitalError.firebaseError("Failed to fetch hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Fetches hospitals located in a specific city and state.
    public func listHospitals(city: String, state: String) async throws -> [Hospital] {
        do {
            let query = db.collection("hospitals")
                .whereField("citytown", isEqualTo: city)
                .whereField("state", isEqualTo: state)
            let snapshot = try await query.getDocuments()
            return try snapshot.documents.map { document in
                try mapDocumentToHospital(id: document.documentID, data: document.data())
            }
        } catch {
            throw HospitalError.firebaseError("Failed to fetch hospitals in \(city), \(state): \(error.localizedDescription)")
        }
    }

    /// Searches for hospitals by a partial name match.
    public func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital] {
        do {
            let query = db.collection("hospitals")
                .whereField("name", isGreaterThanOrEqualTo: partialName ?? "")
                .whereField("name", isLessThanOrEqualTo: (partialName ?? "") + "\u{f8ff}")
            let snapshot = try await query.getDocuments()
            return try snapshot.documents.map { document in
                try mapDocumentToHospital(id: document.documentID, data: document.data())
            }
        } catch {
            throw HospitalError.firebaseError("Failed to search hospitals by name \(partialName): \(error.localizedDescription)")
        }
    }

    /// Increments the delivery count for a specific hospital.
    public func incrementDeliveryCount(forHospitalId id: String) async throws {
        do {
            try await db.collection("hospitals").document(id).updateData([
                "deliveryCount": FieldValue.increment(Int64(1))
            ])
        } catch {
            throw HospitalError.firebaseError("Failed to increment delivery count for hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Increments the baby count for a specific hospital.
    public func incrementBabyCount(forHospitalId id: String) async throws {
        do {
            try await db.collection("hospitals").document(id).updateData([
                "babyCount": FieldValue.increment(Int64(1))
            ])
        } catch {
            throw HospitalError.firebaseError("Failed to increment baby count for hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Maps Firestore document data to a `Hospital` object.
    private func mapDocumentToHospital(id: String, data: [String: Any]) throws -> Hospital {
        guard
            let name = data["name"] as? String,
            let address = data["address"] as? String,
            let city = data["citytown"] as? String,
            let state = data["state"] as? String,
            let zipCode = data["zip_code"] as? String,
            let county = data["countyparish"] as? String,
            let type = data["hospital_type"] as? String,
            let ownership = data["hospital_ownership"] as? String,
            let emergencyServices = data["emergency_services"] as? Bool,
            let birthingFriendly = data["meets_criteria_for_birthing_friendly_designation"] as? Bool,
            let deliveryCount = data["deliveryCount"] as? Int,
            let babyCount = data["babyCount"] as? Int
        else {
            throw HospitalError.mappingError("Failed to map hospital data with ID \(id).")
        }
        return Hospital(
            id: id,
            name: name,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            county: county,
            phone: data["telephone_number"] as? String,
            type: type,
            ownership: ownership,
            emergencyServices: emergencyServices,
            birthingFriendly: birthingFriendly,
            deliveryCount: deliveryCount,
            babyCount: babyCount
        )
    }
}
