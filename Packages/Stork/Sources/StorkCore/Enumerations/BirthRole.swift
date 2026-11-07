//
//  BirthRole.swift
//  StorkCore
//
//  The part the user played at a delivery. Optional on `Delivery` (nil = not recorded,
//  and such deliveries always count toward totals). Raw values are persisted — never
//  rename a case.
//

import Foundation

nonisolated public enum BirthRole: String, Codable, Hashable, CaseIterable, Identifiable, Sendable {
    case primaryNurse
    case transitionNurse
    case chargeNurse
    case preceptor
    case student
    case midwife
    case doula
    case resident
    case other

    public var id: BirthRole { self }

    public var displayName: String {
        switch self {
        case .primaryNurse: String(localized: "Primary Nurse", bundle: .module)
        case .transitionNurse: String(localized: "Transition / Baby Nurse", bundle: .module)
        case .chargeNurse: String(localized: "Charge Nurse", bundle: .module)
        case .preceptor: String(localized: "Preceptor", bundle: .module)
        case .student: String(localized: "Student", bundle: .module)
        case .midwife: String(localized: "Midwife", bundle: .module)
        case .doula: String(localized: "Doula", bundle: .module)
        case .resident: String(localized: "Resident", bundle: .module)
        case .other: String(localized: "Other", bundle: .module)
        }
    }

    /// Compact label for list rows and chips.
    public var shortName: String {
        switch self {
        case .primaryNurse: String(localized: "Primary", bundle: .module)
        case .transitionNurse: String(localized: "Transition", bundle: .module)
        case .chargeNurse: String(localized: "Charge", bundle: .module)
        case .preceptor: String(localized: "Preceptor", bundle: .module)
        case .student: String(localized: "Student", bundle: .module)
        case .midwife: String(localized: "Midwife", bundle: .module)
        case .doula: String(localized: "Doula", bundle: .module)
        case .resident: String(localized: "Resident", bundle: .module)
        case .other: String(localized: "Other", bundle: .module)
        }
    }

    public var systemImage: String {
        switch self {
        case .primaryNurse: "cross.case.fill"
        case .transitionNurse: "heart.text.square.fill"
        case .chargeNurse: "person.badge.shield.checkmark.fill"
        case .preceptor: "person.2.fill"
        case .student: "graduationcap.fill"
        case .midwife: "hands.sparkles.fill"
        case .doula: "heart.fill"
        case .resident: "stethoscope"
        case .other: "ellipsis.circle.fill"
        }
    }
}

/// Which roles are left out of the headline birth total. Stored as the comma-separated
/// raw values of the *excluded* roles so the default (empty) means "all roles count" and
/// roles added later count automatically.
nonisolated public struct BirthRoleCounting: Equatable, Sendable {
    public var excluded: Set<BirthRole>

    public init(excluded: Set<BirthRole> = []) { self.excluded = excluded }

    public init(storedValue: String) {
        excluded = Set(storedValue.split(separator: ",").compactMap { BirthRole(rawValue: String($0)) })
    }

    public var storedValue: String {
        excluded.map(\.rawValue).sorted().joined(separator: ",")
    }

    public func counts(_ role: BirthRole?) -> Bool {
        guard let role else { return true }   // unrecorded deliveries always count
        return !excluded.contains(role)
    }

    public mutating func set(_ role: BirthRole, counted: Bool) {
        if counted { excluded.remove(role) } else { excluded.insert(role) }
    }
}
