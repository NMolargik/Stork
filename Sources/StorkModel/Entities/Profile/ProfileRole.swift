//
//  ProfileRole.swift
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

/// Represents the various roles a user can have within the Stork application.
public enum ProfileRole: String, Codable, Hashable, CaseIterable, Identifiable, CustomStringConvertible {
    
    // MARK: - Cases
    
    /// Represents a nurse role.
    case nurse
    
    /// Represents a doctor role.
    case doctor
    
    /// Represents any other role not explicitly defined.
    case other
    
    // MARK: - Identifiable Conformance
    
    /// Provides a unique identifier for each `ProfileRole` instance.
    public var id: ProfileRole { self }
    
    // MARK: - CustomStringConvertible Conformance
    
    /// A human-readable description of the `ProfileRole`.
    public var description: String {
        switch self {
        case .nurse:
            return "Nurse"
        case .doctor:
            return "Doctor"
        case .other:
            return "Other" // Updated to provide a meaningful description.
        }
    }
}
