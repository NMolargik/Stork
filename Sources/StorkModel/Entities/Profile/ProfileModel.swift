//
//  ProfileModel.swift
//
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation
import UIKit

public struct Profile: Identifiable, Codable, Hashable {
    public var id: String
    public var primaryHospitalId: String
    public var musterId: String
    public var firstName: String
    public var lastName: String
    public var email: String
    public var birthday: Date
    public var joinDate: String
    public var role: ProfileRole
    public var isAdmin: Bool
    public var profilePicture: UIImage? // Optional profile picture

    // Custom date formatter for DD-MM-YYYY format
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    // Convert the model to a dictionary for Firestore compatibility
    var dictionary: [String: Any] {
        return [
            "id": id,
            "primaryHospitalId": primaryHospitalId,
            "musterId": musterId,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "birthday": birthday,
            "joinDate": joinDate,
            "role": role.rawValue,
            "isAdmin": isAdmin
        ]
    }

    // Initialize from Firestore data dictionary
    public init?(from dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let primaryHospitalId = dictionary["primaryHospitalId"] as? String,
            let musterId = dictionary["musterId"] as? String,
            let firstName = dictionary["firstName"] as? String,
            let lastName = dictionary["lastName"] as? String,
            let email = dictionary["email"] as? String,
            let birthday = dictionary["birthday"] as? Date, // Already a string
            let joinDate = dictionary["joinDate"] as? String, // Already a string
            let roleString = dictionary["role"] as? String,
            let role = ProfileRole(rawValue: roleString), // Decode role
            let isAdmin = dictionary["isAdmin"] as? Bool
        else {
            return nil
        }

        self.id = id
        self.primaryHospitalId = primaryHospitalId
        self.musterId = musterId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.birthday = birthday
        self.joinDate = joinDate
        self.role = role
        self.isAdmin = isAdmin
        self.profilePicture = nil // Default to nil
    }

    // Initialize from Strings for birthday and joinDate
    public init(
        id: String,
        primaryHospitalId: String,
        musterId: String,
        firstName: String,
        lastName: String,
        email: String,
        birthday: Date,
        joinDate: String,
        role: ProfileRole,
        isAdmin: Bool,
        profilePicture: UIImage? = nil
    ) {
        self.id = id
        self.primaryHospitalId = primaryHospitalId
        self.musterId = musterId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.birthday = birthday
        self.joinDate = joinDate
        self.role = role
        self.isAdmin = isAdmin
        self.profilePicture = profilePicture
    }
    
    public init(thisIsTemporary: Bool?) {
        self.id = UUID().uuidString
        self.primaryHospitalId = ""
        self.musterId = ""
        self.firstName = ""
        self.lastName = ""
        self.email = ""
        self.birthday = Date()
        self.joinDate = Date().description
        self.role = ProfileRole.other
        self.isAdmin = false
        self.profilePicture = nil
    }

    // Exclude profilePicture from Codable
    private enum CodingKeys: String, CodingKey {
        case id, primaryHospitalId, musterId, firstName, lastName, email, birthday, joinDate, role, isAdmin
    }

    // Custom Hashable implementation
    public static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id &&
            lhs.primaryHospitalId == rhs.primaryHospitalId &&
            lhs.musterId == rhs.musterId &&
            lhs.firstName == rhs.firstName &&
            lhs.lastName == rhs.lastName &&
            lhs.email == rhs.email &&
            lhs.birthday == rhs.birthday &&
            lhs.joinDate == rhs.joinDate &&
            lhs.role == rhs.role &&
            lhs.isAdmin == rhs.isAdmin
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(primaryHospitalId)
        hasher.combine(musterId)
        hasher.combine(firstName)
        hasher.combine(lastName)
        hasher.combine(email)
        hasher.combine(birthday)
        hasher.combine(joinDate)
        hasher.combine(role)
        hasher.combine(isAdmin)
    }
}
