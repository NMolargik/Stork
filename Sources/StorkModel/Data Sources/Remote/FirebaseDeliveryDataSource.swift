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

    /// Creates a new delivery record in Firestore and returns the newly created `Delivery`.
    ///
    /// - Parameter delivery: The `Delivery` object to create.
    /// - Returns: The newly created `Delivery`, including a newly generated document ID if successful.
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If an error occurs while creating the delivery.
    public func createDelivery(delivery: Delivery) async throws -> Delivery {
        do {
            // Convert our delivery to a dictionary suitable for Firestore
            let data = delivery.dictionary

            // Create the new Firestore document
            let docRef = try await db.collection("Delivery").addDocument(data: data)
            
            // Build a new Delivery object that includes the Firestore-generated document ID
            var newDelivery = delivery
            newDelivery.id = docRef.documentID
            
            return newDelivery
        } catch {
            throw DeliveryError.firebaseError("Failed to create delivery: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update an Existing Delivery Record

    /// Updates an existing delivery record in Firestore and returns the updated `Delivery`.
    ///
    /// - Parameter delivery: The `Delivery` object containing updated data.
    /// - Returns: The updated `Delivery`. (If Firestore auto-modifies fields, consider re-fetching the updated document if needed.)
    /// - Throws:
    ///   - `DeliveryError.firebaseError`: If an error occurs while updating the delivery.
    public func updateDelivery(delivery: Delivery) async throws -> Delivery {
        do {
            let data = delivery.dictionary
            try await db.collection("Delivery").document(delivery.id).updateData(data)
            return delivery
        } catch {
            throw DeliveryError.firebaseError("Failed to update delivery: \(error.localizedDescription)")
        }
    }

    // MARK: - Retrieve a Single Delivery by ID

    /// Fetches a single delivery by its unique ID, throwing an error if not found.
    ///
    /// - Parameter id: The unique ID of the delivery to fetch.
    /// - Returns: A `Delivery` object representing the delivery with the specified ID.
    /// - Throws:
    ///   - `DeliveryError.notFound`: If no delivery with the specified ID is found.
    ///   - `DeliveryError.firebaseError`: If an error occurs while fetching the delivery.
    public func getDelivery(byId id: String) async throws -> Delivery {
        do {
            let document = try await db.collection("Delivery").document(id).getDocument()

            // Safely unwrap the optional data
            guard let data = document.data() else {
                throw DeliveryError.notFound(id)
            }

            guard let delivery = Delivery(from: data, id: document.documentID) else {
                throw DeliveryError.firebaseError(
                    "Failed to parse data into Delivery model (ID: \(document.documentID))"
                )
            }
            return delivery
        } catch let error as DeliveryError {
            throw error
        } catch {
            throw DeliveryError.firebaseError("Failed to fetch delivery with ID \(id): \(error.localizedDescription)")
        }
    }

    // MARK: - List Deliveries with Filters & 6-Month Pagination

    /// Lists deliveries based on optional filters, supporting pagination in **6-month intervals**.
    ///
    /// - Parameters:
    ///   - userId: An optional filter for the user ID associated with the delivery.
    ///   - userFirstName: An optional filter for the first name of the user.
    ///   - hospitalId: An optional filter for the hospital ID.
    ///   - hospitalName: An optional filter for the hospital name.
    ///   - musterId: An optional filter for the muster ID.
    ///   - date: An optional filter for a specific delivery date.
    ///   - babyCount: An optional filter for the number of babies in the delivery.
    ///   - deliveryMethod: An optional filter (e.g., vaginal, c-section).
    ///   - epiduralUsed: An optional filter for whether an epidural was used.
    ///   - startDate: (Pagination) The **start date of the 6-month range**. If provided, only deliveries on/after this date are included.
    ///   - endDate: (Pagination) The **end date of the 6-month range**. If provided, only deliveries before this date are included.
    ///
    /// - Returns: An array of `Delivery` objects matching the specified filters within the given 6-month range.
    /// - Throws: `DeliveryError.firebaseError` if the operation fails.
    public func listDeliveries(
        userId: String? = nil,
        userFirstName: String? = nil,
        hospitalId: String? = nil,
        hospitalName: String? = nil,
        musterId: String? = nil,
        date: Date? = nil,
        babyCount: Int? = nil,
        deliveryMethod: DeliveryMethod? = nil,
        epiduralUsed: Bool? = nil,
        startDate: Date?,
        endDate: Date?
    ) async throws -> [Delivery] {
        do {
            var query: Query = db.collection("Delivery").order(by: "date", descending: true)

            // MARK: - Apply Filters
            if let userId { query = query.whereField("userId", isEqualTo: userId) }
            if let musterId { query = query.whereField("musterId", isEqualTo: musterId) }
            if let hospitalId { query = query.whereField("hospitalId", isEqualTo: hospitalId) }
            if let deliveryMethod { query = query.whereField("deliveryMethod", isEqualTo: deliveryMethod.rawValue) }
            if let epiduralUsed { query = query.whereField("epiduralUsed", isEqualTo: epiduralUsed) }
            if let babyCount { query = query.whereField("babyCount", isEqualTo: babyCount) }

            // MARK: - Pagination (6-month intervals)
            if let startDate {
                let timestamp = startDate.timeIntervalSince1970
                query = query.whereField("date", isGreaterThanOrEqualTo: timestamp)
            }
            if let endDate {
                let timestamp = endDate.timeIntervalSince1970
                query = query.whereField("date", isLessThan: timestamp)
            }

            // MARK: - Fetch Documents
            let snapshot = try await query.getDocuments()
            print("Retrieved \(snapshot.documents.count) documents from Firestore.")

            let deliveries: [Delivery] = snapshot.documents.compactMap { document in
                do {
                    let delivery = Delivery(from: document.data(), id: document.documentID)
                    print("Loaded delivery with ID: \(delivery?.id)")
                    return delivery
                } catch {
                    print("Error decoding delivery document \(document.documentID): \(error.localizedDescription)")
                    return nil
                }
            }

            print("Collected Deliveries: \(deliveries.count)")
            return deliveries
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
