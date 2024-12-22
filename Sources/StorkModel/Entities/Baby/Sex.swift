//
//  Sex.swift
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation
import SwiftUI

/// Represents the sex of a baby within the Stork application.
public enum Sex: String, Codable, Hashable, CaseIterable, Identifiable, CustomStringConvertible {
    
    // MARK: - Cases
    
    /// Represents a male baby.
    case male
    
    /// Represents a female baby.
    case female
    
    /// Represents an undetermined or unspecified sex.
    case loss
    
    // MARK: - Identifiable Conformance
    
    /// Provides a unique identifier for each `Sex` instance.
    public var id: Sex { self }
    
    // MARK: - CustomStringConvertible Conformance
    
    /// A human-readable description of the `Sex` instance.
    public var description: String {
        switch self {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .loss:
            return "Loss"
        }
    }
    
    // MARK: - Computed Properties
    
    /// Returns the SwiftUI `Color` associated with each sex.
    ///
    /// - Returns: A `Color` representing the sex.
    public var color: Color {
        switch self {
        case .male:
            return Color.blue
        case .female:
            return Color.pink
        case .loss:
            return Color.purple
        }
    }
}
