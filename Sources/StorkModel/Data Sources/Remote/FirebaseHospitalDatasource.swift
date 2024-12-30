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
    
    /// Creates a new hospital record in Firestore and returns the newly created `Hospital`.
    ///
    /// - Parameter hospital: The `Hospital` object to create.
    /// - Returns: The newly created `Hospital`, updated with the newly generated Firestore `id`.
    /// - Throws: `HospitalError.creationFailed` if creation fails.
    public func createHospital(hospital: Hospital) async throws -> Hospital {
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
            let docRef = try await db.collection("Hospital").addDocument(data: data)
            
            // Create a new Hospital that includes the Firestore-generated document ID.
            var newHospital = hospital
            newHospital.id = docRef.documentID
            return newHospital
        } catch {
            throw HospitalError.creationFailed("Failed to create hospital: \(error.localizedDescription)")
        }
    }

    /// Updates the hospital stats in Firestore by incrementing `deliveryCount` and `babyCount`.
    ///
    /// - Parameters:
    ///   - hospital: The `Hospital` object whose stats should be updated. Must include a valid Firestore `id`.
    ///   - additionalDeliveryCount: The number by which to increment `deliveryCount`.
    ///   - additionalBabyCount: The number by which to increment `babyCount`.
    /// - Returns: The updated `Hospital` object with local counts incremented.
    /// - Throws: `HospitalError.updateFailed` if the Firestore update operation fails.
    public func updateHospitalStats(
        hospital: Hospital,
        additionalDeliveryCount: Int,
        additionalBabyCount: Int
    ) async throws -> Hospital {
        do {
            // Atomically increment the fields in Firestore
            let docRef = db.collection("Hospital").document(hospital.id)
            try await docRef.updateData([
                "deliveryCount": FieldValue.increment(Int64(additionalDeliveryCount)),
                "babyCount": FieldValue.increment(Int64(additionalBabyCount))
            ])
            
            // If Firestore didn't throw an error, safely increment local stats
            var updatedHospital = hospital
            updatedHospital.deliveryCount += additionalDeliveryCount
            updatedHospital.babyCount += additionalBabyCount
            
            // Return the updated hospital
            return updatedHospital
        } catch {
            throw HospitalError.updateFailed("Failed to update hospital stats: \(error.localizedDescription)")
        }
    }

    /// Fetches a hospital by its unique ID from Firestore.
    ///
    /// - Parameter id: The Firestore document ID for the hospital.
    /// - Returns: A `Hospital` object if found.
    /// - Throws: `HospitalError.notFound` if the hospital document doesn't exist.
    public func getHospital(byId id: String) async throws -> Hospital {
        do {
            let document = try await db.collection("Hospital").document(id).getDocument()
            guard let data = document.data() else {
                throw HospitalError.notFound("Hospital with ID \(id) not found.")
            }

            // Insert the doc ID into the data so `mapDocumentToHospital` can pick it up
            var docData = data
            docData["id"] = document.documentID

            return try mapDocumentToHospital(data: docData)
        } catch {
            throw HospitalError.notFound("Failed to fetch hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Fetches hospitals located in a specific city and state.
    ///
    /// - Parameters:
    ///   - city: The city to filter hospitals by.
    ///   - state: The state to filter hospitals by.
    /// - Returns: A list of matching `Hospital` objects.
    /// - Throws: `HospitalError.notFound` if no hospitals are found or Firestore errors.
    public func listHospitals(city: String, state: String) async throws -> [Hospital] {
        do {
            // Automatically uppercase both city and state (if your data is stored in uppercase).
            let uppercasedCity = city.uppercased()
            let uppercasedState = state.uppercased()
            
            let query = db.collection("Hospital")
                .whereField("citytown", isEqualTo: uppercasedCity)
                .whereField("state", isEqualTo: uppercasedState)
            
            let snapshot = try await query.getDocuments()
            
            return try snapshot.documents.map { document in
                var data = document.data()
                data["id"] = document.documentID  // Ensure 'id' field is set
                return try mapDocumentToHospital(data: data)
            }
        } catch {
            throw HospitalError.notFound("Failed to fetch hospitals in \(city), \(state): \(error.localizedDescription)")
        }
    }

    @MainActor
    /// Searches for hospitals by a partial name match.
    ///
    /// - Parameter partialName: A substring (case-insensitive) to filter hospital names by.
    /// - Returns: A list of matching `Hospital` objects.
    /// - Throws: `HospitalError.notFound` if none are found or Firestore errors.
    public func listHospitalsByPartialName(partialName: String?) async throws -> [Hospital] {
        guard let partialName = partialName, !partialName.isEmpty else {
            throw HospitalError.notFound("Invalid search text.")
        }

        // Normalize user input to uppercase to match Firestore data (assuming your data is stored uppercase).
        let normalizedPartialName = partialName.uppercased()

        do {
            let query = db.collection("Hospital")
                .whereField("facility_name", isGreaterThanOrEqualTo: normalizedPartialName)
                .whereField("facility_name", isLessThan: normalizedPartialName + "\u{F8FF}")
                .order(by: "facility_name")

            let snapshot = try await query.getDocuments()

            let hospitals = try snapshot.documents.map { document in
                var data = document.data()
                data["id"] = document.documentID  // Ensure 'id' field is set
                return try mapDocumentToHospital(data: data)
            }
            
            if hospitals.isEmpty {
                throw HospitalError.notFound("No hospitals matching '\(partialName)' found.")
            }
            
            return hospitals
        } catch {
            throw HospitalError.notFound("Failed to search hospitals by name '\(partialName)': \(error.localizedDescription)")
        }
    }

    /// Increments the delivery count for a specific hospital and returns the updated `Hospital`.
    ///
    /// - Parameter id: The hospital's Firestore document ID.
    /// - Returns: The updated `Hospital`.
    /// - Throws: `HospitalError.updateFailed` if increment operation or re-fetch fails.
    public func incrementDeliveryCount(forHospitalId id: String) async throws -> Hospital {
        do {
            // Atomically increment "deliveryCount" by 1
            try await db.collection("Hospital").document(id).updateData([
                "deliveryCount": FieldValue.increment(Int64(1))
            ])
            
            // Fetch updated hospital
            let doc = try await db.collection("Hospital").document(id).getDocument()
            guard let data = doc.data() else {
                throw HospitalError.notFound("Hospital with ID \(id) not found after increment.")
            }

            var docData = data
            docData["id"] = doc.documentID
            return try mapDocumentToHospital(data: docData)
        } catch {
            throw HospitalError.updateFailed("Failed to increment delivery count for hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Increments the baby count for a specific hospital and returns the updated `Hospital`.
    ///
    /// - Parameters:
    ///   - babyCount: The number of babies to add.
    ///   - id: The hospital's Firestore document ID.
    /// - Returns: The updated `Hospital`.
    /// - Throws: `HospitalError.updateFailed` if increment operation or re-fetch fails.
    public func incrementBabyCount(babyCount: Int, forHospitalId id: String) async throws -> Hospital {
        do {
            // Atomically increment "babyCount" by the given value
            try await db.collection("Hospital").document(id).updateData([
                "babyCount": FieldValue.increment(Int64(babyCount))
            ])
            
            // Fetch updated hospital
            let doc = try await db.collection("Hospital").document(id).getDocument()
            guard let data = doc.data() else {
                throw HospitalError.notFound("Hospital with ID \(id) not found after baby count increment.")
            }

            var docData = data
            docData["id"] = doc.documentID
            return try mapDocumentToHospital(data: docData)
        } catch {
            throw HospitalError.updateFailed("Failed to increment baby count for hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    /// Deletes a hospital from Firestore.
    ///
    /// - Parameter id: The Firestore document ID of the hospital to delete.
    /// - Throws: `HospitalError.deletionFailed` if the delete operation fails.
    public func deleteHospital(byId id: String) async throws {
        do {
            try await db.collection("Hospital").document(id).delete()
        } catch {
            throw HospitalError.deletionFailed("Failed to delete hospital with ID \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Maps Firestore document data to a `Hospital` object.
    ///
    /// **Important**: Ensure `data["id"]` is set before calling this method, or it will throw an error.
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
