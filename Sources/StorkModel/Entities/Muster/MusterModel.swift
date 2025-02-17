//
//  MusterModel.swift
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

/// Represents a muster within the Stork application.
/// A muster is a group that organizes profiles (users) associated with a primary hospital.
public struct Muster: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the muster.
    public var id: String
    
    /// List of profile IDs associated with the muster.
    public var profileIds: [String]
    
    /// Identifier for the primary hospital associated with the muster.
    public var primaryHospitalId: String
    
    /// List of administrator profile IDs within the muster.
    public var administratorProfileIds: [String]
    
    /// Name of the muster.
    public var name: String

    /// Converts the muster data into a dictionary format, suitable for Firestore or similar databases.
    var dictionary: [String: Any] {
        return [
            "profileIds": profileIds,
            "primaryHospitalId": primaryHospitalId,
            "administratorProfileIds": administratorProfileIds,
            "name": name
        ]
    }
    
    // MARK: - Initializers
    
    /// Initializes a `Muster` instance from a dictionary and an optional ID.
    ///
    /// - Parameters:
    ///   - dictionary: A dictionary containing muster data.
    ///   - id: Optional ID for the muster. If `nil`, initialization fails.
    public init?(from dictionary: [String: Any], id: String?) {
        guard
            let id = id,
            let profileIds = dictionary["profileIds"] as? [String],
            let primaryHospitalId = dictionary["primaryHospitalId"] as? String,
            let administratorProfileIds = dictionary["administratorProfileIds"] as? [String],
            let name = dictionary["name"] as? String
        else {
            print("Initialization failed: Missing or invalid required fields.")
            return nil
        }
        
        self.id = id
        self.profileIds = profileIds
        self.primaryHospitalId = primaryHospitalId
        self.administratorProfileIds = administratorProfileIds
        self.name = name
    }
    
    /// Initializes a `Muster` instance with explicit parameters.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the muster.
    ///   - profileIds: List of profile IDs associated with the muster.
    ///   - primaryHospitalId: Identifier for the primary hospital.
    ///   - administratorProfileIds: List of administrator profile IDs.
    ///   - name: Name of the muster.
    public init(
        id: String,
        profileIds: [String],
        primaryHospitalId: String,
        administratorProfileIds: [String],
        name: String
    ) {
        self.id = id
        self.profileIds = profileIds
        self.primaryHospitalId = primaryHospitalId
        self.administratorProfileIds = administratorProfileIds
        self.name = name
    }
    
    // MARK: - Default Initializer
    
    /// Initializes a `Muster` instance with default values.
    /// This initializer can be useful for creating placeholder or testing instances.
    public init() {
        self.id = UUID().uuidString
        self.profileIds = []
        self.primaryHospitalId = ""
        self.administratorProfileIds = []
        self.name = "New Muster"
    }
    
    // MARK: - Codable Conformance
    
    /// Specifies the coding keys for encoding and decoding.
    private enum CodingKeys: String, CodingKey {
        case id
        case profileIds
        case primaryHospitalId
        case administratorProfileIds
        case name
    }
    
    // MARK: - Hashable Conformance
    
    /// Determines equality between two `Muster` instances based on their properties.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `Muster` instance.
    ///   - rhs: The right-hand side `Muster` instance.
    /// - Returns: `true` if all properties are equal; otherwise, `false`.
    public static func == (lhs: Muster, rhs: Muster) -> Bool {
        return lhs.id == rhs.id &&
            lhs.profileIds == rhs.profileIds &&
            lhs.primaryHospitalId == rhs.primaryHospitalId &&
            lhs.administratorProfileIds == rhs.administratorProfileIds &&
            lhs.name == rhs.name
    }
    
    /// Generates a hash value for the `Muster` instance by combining its properties.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(profileIds)
        hasher.combine(primaryHospitalId)
        hasher.combine(administratorProfileIds)
        hasher.combine(name)
    }
}
