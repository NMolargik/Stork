//
//  BabyModel.swift
//
//  Created by Nick Molargik on 11/4/24.
//

import Foundation

/// Represents a baby born during a delivery within the Stork application.
public struct Baby: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the baby.
    public var id: String
    
    /// Identifier of the delivery associated with the baby.
    public var deliveryId: String
    
    /// Birthday of the baby.
    public var birthday: Date
    
    /// Height of the baby in inches or centimeters, based on app settings.
    public var height: Double
    
    /// Weight of the baby in ounces or kilograms, based on app settings.
    public var weight: Double
    
    /// Indicates whether the baby was part of a nurse catch.
    public var nurseCatch: Bool
    
    /// Indicates whether the baby went to NICU
    public var nicuStay: Bool
    
    /// Sex of the baby.
    public var sex: Sex
    
    
    /// Converts the `Baby` instance into a dictionary format suitable for Firestore storage.
    ///
    /// - Returns: A dictionary representation of the baby.
    var dictionary: [String: Any] {
        return [
            "id": id,
            "birthday": birthday.description,
            "height": height,
            "weight": weight,
            "sex": sex.rawValue,
            "deliveryId": deliveryId,
            "nicuStay": nicuStay,
            "nurseCatch": nurseCatch
        ]
    }
    
    // MARK: - Initializers
    
    /// Initializes a `Baby` instance from a Firestore data dictionary.
    ///
    /// - Parameter dictionary: A dictionary containing baby data fetched from Firestore.
    public init?(from dictionary: [String: Any]) {
        // Debugging: Print the incoming dictionary (consider removing in production)
        
        let isoFormatter = ISO8601DateFormatter()
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        // Extract and validate required fields.
        guard
            let id = dictionary["id"] as? String,
            let deliveryId = dictionary["deliveryId"] as? String,
            let birthdayString = dictionary["birthday"] as? String,
            let height = dictionary["height"] as? Double,
            let weight = dictionary["weight"] as? Double,
            let nurseCatch = dictionary["nurseCatch"] as? Bool,
            let nicuStay = dictionary["nicuStay"] as? Bool,
            let sexRawValue = dictionary["sex"] as? String,
            let sex = Sex(rawValue: sexRawValue)
        else {
            print("Initialization failed: Missing or invalid required fields for baby.")
            return nil
        }
        
        // Parse birthday with fallback formatter.
        guard let birthday = isoFormatter.date(from: birthdayString) ??
                              fallbackFormatter.date(from: birthdayString) else {
            print("Initialization failed: Invalid birthday format - \(birthdayString)")
            return nil
        }
        
        self.id = id
        self.deliveryId = deliveryId
        self.birthday = birthday
        self.height = height
        self.weight = weight
        self.nurseCatch = nurseCatch
        self.nicuStay = nicuStay
        self.sex = sex
    }
    
    /// Initializes a `Baby` instance with explicit parameters.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the baby.
    ///   - deliveryId: Identifier of the associated delivery.
    ///   - birthday: Birthday of the baby.
    ///   - height: Height of the baby.
    ///   - weight: Weight of the baby.
    ///   - nurseCatch: Indicates if the baby was part of a nurse catch.
    ///   - nicuStay: Indicates if the baby stayed in NICU
    ///   - sex: Sex of the baby.
    public init(
        id: String,
        deliveryId: String,
        birthday: Date,
        height: Double,
        weight: Double,
        nurseCatch: Bool,
        nicuStay: Bool,
        sex: Sex
    ) {
        self.id = id
        self.deliveryId = deliveryId
        self.birthday = birthday
        self.height = height
        self.weight = weight
        self.nurseCatch = nurseCatch
        self.nicuStay = nicuStay
        self.sex = sex
    }
    
    public init(deliveryId: String, nurseCatch: Bool, nicuStay: Bool, sex: Sex, weight: Double, height: Double) {
        self.init(deliveryId: deliveryId, nurseCatch: nurseCatch, nicuStay: nicuStay, sex: sex)
        self.weight = weight
        self.height = height
    }
    
    /// Initializes a `Baby` instance with default values.
    /// Useful for creating placeholder or testing instances.
    ///
    /// - Parameters:
    ///   - deliveryId: Identifier of the associated delivery.
    ///   - nurseCatch: Indicates if the baby was part of a nurse catch.
    ///   - sex: Sex of the baby.
    public init(deliveryId: String, nurseCatch: Bool, nicuStay: Bool, sex: Sex) {
        self.id = UUID().uuidString
        self.deliveryId = deliveryId
        self.birthday = Date() // Defaults to current date; consider adjusting as needed.
        self.height = 19.0      // Default height; adjust based on unit settings.
        self.weight = 121.6     // Default weight; adjust based on unit settings.
        self.nurseCatch = nurseCatch
        self.nicuStay = nicuStay
        self.sex = sex
    }
    
    // MARK: - Codable Conformance
    
    /// Specifies the coding keys for encoding and decoding.
    private enum CodingKeys: String, CodingKey {
        case id
        case deliveryId
        case birthday
        case height
        case weight
        case nurseCatch
        case nicuStay
        case sex
    }
    
    // MARK: - Hashable Conformance
    
    /// Determines equality between two `Baby` instances based on their properties.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `Baby` instance.
    ///   - rhs: The right-hand side `Baby` instance.
    /// - Returns: `true` if all properties are equal; otherwise, `false`.
    public static func == (lhs: Baby, rhs: Baby) -> Bool {
        return lhs.id == rhs.id &&
            lhs.deliveryId == rhs.deliveryId &&
            lhs.birthday == rhs.birthday &&
            lhs.height == rhs.height &&
            lhs.weight == rhs.weight &&
            lhs.nurseCatch == rhs.nurseCatch &&
            lhs.nicuStay == rhs.nicuStay &&
            lhs.sex == rhs.sex
    }
    
    /// Generates a hash value for the `Baby` instance by combining its properties.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(deliveryId)
        hasher.combine(birthday)
        hasher.combine(height)
        hasher.combine(weight)
        hasher.combine(nurseCatch)
        hasher.combine(nicuStay)
        hasher.combine(sex)
    }
}
