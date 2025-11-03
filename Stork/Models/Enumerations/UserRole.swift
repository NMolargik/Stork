//
//  UserRole.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

enum UserRole: String, Codable, Hashable, CaseIterable, Identifiable, CustomStringConvertible {
    case nurse
    case doctor
    case other

    public var id: UserRole { self }

    public var description: String {
        switch self {
        case .nurse:
            return "Nurse"
        case .doctor:
            return "Doctor"
        case .other:
            return "Other"
        }
    }
}
