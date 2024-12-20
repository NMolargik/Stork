//
//  FirebaseDeliveryDataSource.swift
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

/// A data source responsible for interacting with the Firebase Firestore database to manage delivery records.
public class FirebaseDeliveryDataSource: DeliveryRemoteDataSourceInterface {
    /// The Firestore database instance.
    private let db: Firestore

    /// Initializes the FirebaseDeliveryDataSource with a Firestore instance.
    public init() {
        self.db = Firestore.firestore()
    }
    
    // MARK: - Create a New Delivery Record

    /// Creates a new delivery record in Firestore.
    ///
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If an error occurs while creating the delivery.
    public func createDelivery(delivery: Delivery) async throws {
        do {
            let data = delivery.dictionary
            let reference = try await db.collection("Delivery").addDocument(data: data)
        } catch {
            throw DeliveryError.firebaseError("Failed to create delivery: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update an Existing Delivery Record

    /// Updates an existing delivery record in Firestore.
    ///
    /// - Parameter delivery: The `Delivery` object containing updated data.
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If an error occurs while updating the delivery.
    public func updateDelivery(delivery: Delivery) async throws {
        do {
            let data = delivery.dictionary
            try await db.collection("Delivery").document(delivery.id).updateData(data)
        } catch {
            throw DeliveryError.firebaseError("Failed to update delivery: \(error.localizedDescription)")
        }
    }

    // MARK: - Retrieve a Single Delivery by ID

    /// Fetches a single delivery by its unique ID.
    ///
    /// - Parameter id: The unique ID of the delivery to fetch.
    /// - Returns: A `Delivery` object representing the delivery with the specified ID.
    /// - Throws:
    ///   - `DeliveryError.notFound`: If no delivery with the specified ID is found.
    ///   - `DeliveryError.firebaseError`: If an error occurs while fetching the delivery.
    public func getDelivery(byId id: String) async throws -> Delivery? {
        do {
            let document = try await db.collection("Delivery").document(id).getDocument()

            // Safely unwrap the optional data
            guard let data = document.data() else {
                throw DeliveryError.notFound(id)
            }

            // Parse data into Delivery model
            return Delivery(from: data, id: document.documentID)
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.firebaseError("Failed to fetch delivery with ID \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - List Deliveries with Filters

    /// Lists deliveries based on optional filters.
    ///
    /// - Parameters:
    ///   - userId: An optional filter for id of the user associated with the delivery
    ///   - userFirstName: An optional filter for the first name of the user associated with the delivery
    ///   - hospitalId: An optional filter for the hospital ID associated with the delivery.
    ///   - musterId: An optional filter for the muster ID associated with the delivery.
    ///   - date: An optional filter for the delivery date.
    ///   - babyCount: An optional filter for the number of babies in the delivery.
    ///   - deliveryMethod: An optional filter for the delivery method (e.g., vaginal, c-section).
    ///   - epiduralUsed: An optional filter for whether an epidural was used.
    /// - Returns: An array of `Delivery` objects matching the specified filters.
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If an error occurs while fetching the deliveries.
    public func listDeliveries(
        userId: String? = nil,
        userFirstName: String? = nil,
        hospitalId: String? = nil,
        musterId: String? = nil,
        date: Date? = nil,
        babyCount: Int? = nil,
        deliveryMethod: DeliveryMethod? = nil,
        epiduralUsed: Bool? = nil
    ) async throws -> [Delivery] {
        do {
            var query: Query = db.collection("Delivery")

            if let userId = userId {
                query = query.whereField("userId", isEqualTo: userId)
            }
            if let userFirstName = userFirstName {
                query = query.whereField("userFirstName", isEqualTo: userFirstName)
            }
            if let hospitalId = hospitalId {
                query = query.whereField("hospitalId", isEqualTo: hospitalId)
            }
            if let musterId = musterId {
                query = query.whereField("musterId", isEqualTo: musterId)
            }
            if let date = date {
                query = query.whereField("date", isEqualTo: date.timeIntervalSince1970)
            }
            if let babyCount = babyCount {
                query = query.whereField("babyCount", isEqualTo: babyCount)
            }
            if let deliveryMethod = deliveryMethod {
                query = query.whereField("deliveryMethod", isEqualTo: deliveryMethod.rawValue)
            }
            if let epiduralUsed = epiduralUsed {
                query = query.whereField("epiduralUsed", isEqualTo: epiduralUsed)
            }

            // Fetch documents that match the query
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { document in
                let data = document.data()
                return Delivery(from: data, id: document.documentID)
            }
        } catch {
            throw DeliveryError.firebaseError("Failed to fetch deliveries: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete an Existing Delivery Record

    /// Deletes an existing delivery record from Firestore.
    ///
    /// - Parameter delivery: The `Delivery` object to delete.
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If an error occurs while deleting the delivery.
    public func deleteDelivery(delivery: Delivery) async throws {
        do {
            try await db.collection("Delivery").document(delivery.id).delete()
        } catch {
            throw DeliveryError.firebaseError("Failed to delete delivery: \(error.localizedDescription)")
        }
    }
}
