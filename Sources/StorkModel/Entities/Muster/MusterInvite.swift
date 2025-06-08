//
//  MusterInvite.swift
//
//  Created by Nick Molargik on 12/10/24.
//

import SkipFoundation
import Foundation

/// Represents an invitation sent to a user to join a muster within the Stork application.
public struct MusterInvite: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the muster invite.
    public var id: String
    
    /// Identifier of the recipient's profile.
    public var recipientId: String
    
    /// Name of the recipient.
    public var recipientName: String
    
    /// Name of the sender who is inviting the recipient.
    public var senderName: String
    
    /// Name of the muster to which the recipient is being invited.
    public var musterName: String
    
    /// Identifier of the muster.
    public var musterId: String
    
    // MARK: - Computed Properties
    
    /// Converts the muster invite data into a dictionary format, suitable for Firestore or similar databases.
    public var dictionary: [String: Any] {
        return [
            "recipientId": recipientId,
            "recipientName": recipientName,
            "senderName": senderName,
            "musterName": musterName,
            "musterId": musterId
        ]
    }
    
    // MARK: - Initializers
    
    /// Initializes a `MusterInvite` instance from a dictionary and an optional ID.
    ///
    /// - Parameters:
    ///   - dictionary: A dictionary containing muster invite data.
    ///   - id: Optional ID for the muster invite. If `nil`, initialization fails.
    public init?(from dictionary: [String: Any], id: String?) {
        guard
            let id = id,
            let recipientId = dictionary["recipientId"] as? String,
            let recipientName = dictionary["recipientName"] as? String,
            let senderName = dictionary["senderName"] as? String,
            let musterName = dictionary["musterName"] as? String,
            let musterId = dictionary["musterId"] as? String
        else {
            print("Initialization failed: Missing or invalid required fields.")
            return nil
        }
        
        self.id = id
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.senderName = senderName
        self.musterName = musterName
        self.musterId = musterId
    }
    
    /// Initializes a `MusterInvite` instance with explicit parameters.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the muster invite.
    ///   - recipientId: Identifier of the recipient's profile.
    ///   - recipientName: Name of the recipient.
    ///   - senderName: Name of the sender.
    ///   - musterName: Name of the muster.
    ///   - musterId: Identifier of the muster.
    public init(
        id: String,
        recipientId: String,
        recipientName: String,
        senderName: String,
        musterName: String,
        musterId: String
    ) {
        self.id = id
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.senderName = senderName
        self.musterName = musterName
        self.musterId = musterId
    }
    
    // MARK: - Default Initializer
    
    /// Initializes a `MusterInvite` instance with default values.
    /// This initializer can be useful for creating placeholder or testing instances.
    public init() {
        self.id = UUID().uuidString
        self.recipientId = ""
        self.recipientName = ""
        self.senderName = ""
        self.musterName = "New Muster"
        self.musterId = ""
    }
    
    // MARK: - Codable Conformance
    
    /// Specifies the coding keys for encoding and decoding.
    private enum CodingKeys: String, CodingKey {
        case id
        case recipientId
        case recipientName
        case senderName
        case musterName
        case musterId
    }
    
    // MARK: - Hashable Conformance
    
    /// Determines equality between two `MusterInvite` instances based on their properties.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side `MusterInvite` instance.
    ///   - rhs: The right-hand side `MusterInvite` instance.
    /// - Returns: `true` if all properties are equal; otherwise, `false`.
    public static func == (lhs: MusterInvite, rhs: MusterInvite) -> Bool {
        return lhs.id == rhs.id &&
            lhs.recipientId == rhs.recipientId &&
            lhs.recipientName == rhs.recipientName &&
            lhs.senderName == rhs.senderName &&
            lhs.musterName == rhs.musterName &&
            lhs.musterId == rhs.musterId
    }
    
    /// Generates a hash value for the `MusterInvite` instance by combining its properties.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(recipientId)
        hasher.combine(recipientName)
        hasher.combine(senderName)
        hasher.combine(musterName)
        hasher.combine(musterId)
    }
}
