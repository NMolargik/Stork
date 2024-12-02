//
//  DeliveryMethod.swift
//
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

public enum DeliveryMethod: String, CaseIterable, Codable, Hashable {
    case vaginal
    case cSection
    case vBac

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

    public var stringValue: String {
        self.description
    }
}
