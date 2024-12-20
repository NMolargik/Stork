//
//  ProfileModel.swift
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

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

    // Standard Date Formatter
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        #if !SKIP
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        #endif
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
            "birthday": Profile.dateFormatter.string(from: birthday),
            "joinDate": joinDate,
            "role": role.rawValue,
            "isAdmin": isAdmin
        ]
    }

    // Initialize from Firestore data dictionary
    public init?(from dictionary: [String: Any]) {
        let formatter = Profile.dateFormatter

        guard
            let id = dictionary["id"] as? String,
            let firstName = dictionary["firstName"] as? String,
            let lastName = dictionary["lastName"] as? String,
            let joinDateString = dictionary["joinDate"] as? String,
            let email = dictionary["email"] as? String,
            let isAdminInt = dictionary["isAdmin"] as? Int,
            let roleString = dictionary["role"] as? String,
            let role = ProfileRole(rawValue: roleString),
            let birthdayString = dictionary["birthday"] as? String,
            let birthday = formatter.date(from: birthdayString)
        else {
            print("Missing or invalid required fields")
            return nil
        }

        // Assign optional fields with defaults
        let primaryHospitalId = dictionary["primaryHospitalId"] as? String ?? ""
        let musterId = dictionary["musterId"] as? String ?? ""

        self.id = id
        self.primaryHospitalId = primaryHospitalId
        self.musterId = musterId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.birthday = birthday
        self.joinDate = joinDateString // Keeping as a string
        self.role = role
        self.isAdmin = isAdminInt != 0
    }

    // Initialize from explicit parameters
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
        isAdmin: Bool
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
    }

    // Temporary initializer without parameters
    public init() {
        self.id = UUID().uuidString
        self.primaryHospitalId = ""
        self.musterId = ""
        self.firstName = ""
        self.lastName = ""
        self.email = ""
        self.birthday = Date()
        self.joinDate = Profile.dateFormatter.string(from: Date())
        self.role = .nurse
        self.isAdmin = false
    }

    // Exclude profilePictureURL from Codable if necessary
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
