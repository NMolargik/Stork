//
//  DeliveryModel.swift
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// Represents a delivery event within the Stork application.
public struct Delivery: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the delivery.
    public var id: String
    
    /// Identifier of the user associated with the delivery.
    public var userId: String
    
    /// First name of the user associated with the delivery.
    public var userFirstName: String
    
    /// Identifier of the hospital where the delivery took place.
    public var hospitalId: String
    
    /// Name of the hospital where the delivery took place.
    public var hospitalName: String
    
    /// Identifier of the muster associated with the delivery.
    public var musterId: String
    
    /// Date of the delivery.
    public var date: Date
    
    /// List of babies born during the delivery.
    public var babies: [Baby]
    
    /// Total number of babies born during the delivery.
    public var babyCount: Int
    
    /// Method of delivery (e.g., vaginal, cesarean).
    public var deliveryMethod: DeliveryMethod
    
    /// Indicates whether an epidural was used during the delivery.
    public var epiduralUsed: Bool
    
    // MARK: - Computed Properties
    
    /// Converts the `Delivery` instance into a dictionary format suitable for Firestore storage.
    ///
    /// - Returns: A dictionary representation of the delivery.
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "userFirstName": userFirstName,
            "hospitalId": hospitalId,
            "hospitalName": hospitalName,
            "musterId": musterId,
            "date": date.timeIntervalSince1970,
            "babies": babies.map { $0.dictionary },
            "babyCount": babyCount,
            "deliveryMethod": deliveryMethod.rawValue,
            "epiduralUsed": epiduralUsed
        ]
    }
    
    // MARK: - Initializers
    
    /// Initializes a `Delivery` instance from a Firestore data dictionary and an optional ID.
    ///
    /// - Parameters:
    ///   - dictionary: A dictionary containing delivery data fetched from Firestore.
    ///   - id: Optional ID for the delivery. If `nil`, initialization fails.
    public init?(from dictionary: [String: Any], id: String?) {
        guard
            let id = id,
            let userId = dictionary["userId"] as? String,
            let userFirstName = dictionary["userFirstName"] as? String,
            let hospitalId = dictionary["hospitalId"] as? String,
            let hospitalName = dictionary["hospitalName"] as? String,
            let musterId = dictionary["musterId"] as? String,
            let dateTimestamp = dictionary["date"] as? TimeInterval,
            let babiesData = dictionary["babies"] as? [[String: Any]],
            let babyCount = dictionary["babyCount"] as? Int,
            let deliveryMethodRawValue = dictionary["deliveryMethod"] as? String,
            let deliveryMethod = DeliveryMethod(rawValue: deliveryMethodRawValue),
            let epiduralUsed = dictionary["epiduralUsed"] as? Bool
        else {
            print("Initialization failed: Missing or invalid required fields.")
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.userFirstName = userFirstName
        self.hospitalId = hospitalId
        self.hospitalName = hospitalName
        self.musterId = musterId
        self.date = Date(timeIntervalSince1970: dateTimestamp)
        self.babies = babiesData.compactMap { Baby(from: $0) }
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
    }
    
    /// Initializes a `Delivery` instance with explicit parameters.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the delivery.
    ///   - userId: Identifier of the user associated with the delivery.
    ///   - userFirstName: First name of the user.
    ///   - hospitalId: Identifier of the hospital.
    ///   - hospitalName: Name of the hospital.
    ///   - musterId: Identifier of the muster.
    ///   - date: Date of the delivery.
    ///   - babies: List of babies born during the delivery.
    ///   - babyCount: Total number of babies.
    ///   - deliveryMethod: Method of delivery.
    ///   - epiduralUsed: Indicates if an epidural was used.
    public init(
        id: String,
        userId: String,
        userFirstName: String,
        hospitalId: String,
        hospitalName: String,
        musterId: String,
        date: Date,
        babies: [Baby],
        babyCount: Int,
        deliveryMethod: DeliveryMethod,
        epiduralUsed: Bool
    ) {
        self.id = id
        self.userId = userId
        self.userFirstName = userFirstName
        self.hospitalId = hospitalId
        self.hospitalName = hospitalName
        self.musterId = musterId
        self.date = date
        self.babies = babies
        self.babyCount = babyCount
        self.deliveryMethod = deliveryMethod
        self.epiduralUsed = epiduralUsed
    }
    
    /// Initializes a `Delivery` instance with sample data.
    /// This initializer is useful for testing and preview purposes.
    ///
    /// - Parameter sample: A boolean indicating whether to initialize with sample data.
    public init(sample: Bool) {
        self.id = UUID().uuidString
        self.userId = UUID().uuidString
        self.userFirstName = "FirstName"
        self.hospitalId = "1234"
        self.hospitalName = "Parkview Regional Medical Center"
        self.musterId = "5678"
        self.date = Date()
        self.babies = [
            Baby(deliveryId: "12345", nurseCatch: true, sex: Sex.male),
            Baby(deliveryId: "12345", nurseCatch: false, sex: Sex.female),
            Baby(deliveryId: "12345", nurseCatch: false, sex: Sex.loss)
        ]
        self.babyCount = 3
        self.deliveryMethod = .vaginal
        self.epiduralUsed = true
    }
    
    // MARK: - Codable Conformance
    
    /// Specifies the coding keys for encoding and decoding.
    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userFirstName
        case hospitalId
        case hospitalName
        case musterId
        case date
        case babies
        case babyCount
        case deliveryMethod
        case epiduralUsed
    }
    
    // MARK: - Hashable Conformance
    
    /// Determines equality between two `Delivery` instances based on their properties.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `Delivery` instance.
    ///   - rhs: The right-hand side `Delivery` instance.
    /// - Returns: `true` if all properties are equal; otherwise, `false`.
    public static func == (lhs: Delivery, rhs: Delivery) -> Bool {
        return lhs.id == rhs.id &&
            lhs.userId == rhs.userId &&
            lhs.userFirstName == rhs.userFirstName &&
            lhs.hospitalId == rhs.hospitalId &&
            lhs.hospitalName == rhs.hospitalName &&
            lhs.musterId == rhs.musterId &&
            lhs.date == rhs.date &&
            lhs.babies == rhs.babies &&
            lhs.babyCount == rhs.babyCount &&
            lhs.deliveryMethod == rhs.deliveryMethod &&
            lhs.epiduralUsed == rhs.epiduralUsed
    }
    
    /// Generates a hash value for the `Delivery` instance by combining its properties.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userId)
        hasher.combine(userFirstName)
        hasher.combine(hospitalId)
        hasher.combine(hospitalName)
        hasher.combine(musterId)
        hasher.combine(date)
        hasher.combine(babies)
        hasher.combine(babyCount)
        hasher.combine(deliveryMethod)
        hasher.combine(epiduralUsed)
    }
}
