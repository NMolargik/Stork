//
//  DeliveryMethod.swift
//
//  Created by Nick Molargik on 11/26/24.
//

import SkipFoundation

/// Represents the various methods of delivery available within the Stork application.
public enum DeliveryMethod: String, CaseIterable, Codable, Hashable {
    
    // MARK: - Cases
    
    /// Represents a vaginal delivery.
    case vaginal
    
    /// Represents a cesarean section delivery.
    case cSection
    
    /// Represents a vaginal birth after cesarean (VBAC).
    case vBac
    
    // MARK: - Computed Properties
    
    /// Provides a human-readable description of the delivery method.
    public var description: String {
        switch self {
        case .vaginal:
            return "Vaginal"
        case .cSection:
            return "C-Section"
        case .vBac:
            return "VBAC"
        }
    }
    
    /// Returns the string value of the delivery method's description.
    public var stringValue: String {
        self.description
    }
}
