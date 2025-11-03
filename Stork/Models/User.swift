//
//  User.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation
import SwiftData
// NOTE: User is stored as "Profile" in Firebase (legacy mishap)

@Model
final class User {
    var id: UUID = UUID()
    var primaryHospitalId: String?
    var firstName: String = ""
    var lastName: String = ""
    var birthday: Date = Date.now
    var joinDate: String = User.dateFormatter.string(from: Date())
    var role: UserRole = UserRole.nurse
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    init(
        id: UUID = UUID(),
        primaryHospitalId: String? = nil,
        firstName: String,
        lastName: String,
        birthday: Date,
        joinDate: String = User.dateFormatter.string(from: Date()),
        role: UserRole
    ) {
        self.id = id
        self.primaryHospitalId = primaryHospitalId
        self.firstName = firstName
        self.lastName = lastName
        self.birthday = birthday
        self.joinDate = joinDate
        self.role = role
    }
    
    convenience init?(from dictionary: [String: Any], resolveHospital: (String) -> Hospital?) {
        let formatter = User.dateFormatter

        // Stringly-typed Firebase payloads
        let firstName = dictionary["firstName"] as? String ?? ""
        let lastName  = dictionary["lastName"]  as? String ?? ""
        let roleStr   = dictionary["role"]      as? String ?? "nurse"
        let role      = UserRole(rawValue: roleStr) ?? .nurse

        // Dates arrive as "MM/dd/yyyy"
        let joinDate  = (dictionary["joinDate"] as? String) ?? User.dateFormatter.string(from: Date())
        var birthday: Date = Date()
        if let bdayStr = dictionary["birthday"] as? String,
           let parsed = formatter.date(from: bdayStr) {
            birthday = parsed
        }

        // Hospital is referenced by string id, may be empty
        let primaryHospitalId = (dictionary["primaryHospitalId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        // Generate a local UUID (we don't use Firebase's string id as SwiftData primary key)
        self.init(
            id: UUID(),
            primaryHospitalId: primaryHospitalId,
            firstName: firstName,
            lastName: lastName,
            birthday: birthday,
            joinDate: joinDate,
            role: role
        )
    }
    
    convenience init?(from dictionary: [String: Any]) {
        self.init(from: dictionary) { _ in nil }
    }
    
    public init() {
        self.id = UUID()
        self.primaryHospitalId = nil
        self.firstName = ""
        self.lastName = ""
        self.birthday = Date()
        self.joinDate = User.dateFormatter.string(from: Date())
        self.role = .nurse
    }
    
    public var initials: String {
        let firstInitial = firstName.first.map { String($0).uppercased() } ?? ""
        let lastInitial = lastName.first.map { String($0).uppercased() } ?? ""
        return firstInitial + lastInitial
    }

    // MARK: - Samples
    /// A deterministic sample user for previews and testing
    static let sample: User = {
        let formatter = User.dateFormatter
        let bday = formatter.date(from: "04/23/1990") ?? Date()
        return User(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            primaryHospitalId: nil,
            firstName: "Avery",
            lastName: "Johnson",
            birthday: bday,
            joinDate: formatter.string(from: Date()),
            role: .nurse
        )
    }()

    /// Additional variants for convenience
    static let sampleDoctor: User = {
        let formatter = User.dateFormatter
        let bday = formatter.date(from: "01/15/1985") ?? Date()
        return User(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            primaryHospitalId: nil,
            firstName: "Jordan",
            lastName: "Reeves",
            birthday: bday,
            joinDate: formatter.string(from: Date()),
            role: .doctor
        )
    }()

    static let sampleWithHospital: (Hospital?) -> User = { hospital in
        let formatter = User.dateFormatter
        let bday = formatter.date(from: "09/09/1992") ?? Date()
        return User(
            id: UUID(),
            primaryHospitalId: hospital?.remoteId,
            firstName: "Taylor",
            lastName: "Morgan",
            birthday: bday,
            joinDate: formatter.string(from: Date()),
            role: .nurse
        )
    }
}
