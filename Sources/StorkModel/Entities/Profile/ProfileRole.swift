//
//  ProfileRole.swift
//
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

public enum ProfileRole: String, Codable, Hashable, CaseIterable, Identifiable, CustomStringConvertible {
    public var description: String {
        switch self {
        case .nurse: "Nurse"
        case .doctor: "Doctor"
        case .other: ""
    }
}
    case nurse
    case doctor
    case other
    
    public var id: ProfileRole { self }
}
