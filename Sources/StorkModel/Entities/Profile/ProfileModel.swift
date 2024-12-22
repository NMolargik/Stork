//
//  ProfileModel.swift
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

/// Represents a user profile within the Stork application.
public struct Profile: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the profile.
    public var id: String
    
    /// Identifier for the primary hospital associated with the profile.
    public var primaryHospitalId: String
    
    /// Identifier for the muster the profile belongs to.
    public var musterId: String
    
    /// First name of the user.
    public var firstName: String
    
    /// Last name of the user.
    public var lastName: String
    
    /// Email address of the user.
    public var email: String
    
    /// Birthday of the user.
    public var birthday: Date
    
    /// Join date of the user as a string.
    public var joinDate: String
    
    /// Role of the user within the application.
    public var role: ProfileRole
    
    /// Indicates whether the user has administrative privileges.
    public var isAdmin: Bool
    
    /// Predefined date formatter for standardizing date formats.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        #if !SKIP
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        #endif
        return formatter
    }()
    
    // MARK: - Initializers
    
    /// Initializes a `Profile` instance from a Firestore data dictionary.
    /// - Parameter dictionary: A dictionary containing profile data fetched from Firestore.
    public init?(from dictionary: [String: Any]) {
        let formatter = Profile.dateFormatter
        
        // Extract and validate required fields.
        guard
            let id = dictionary["id"] as? String,
            let firstName = dictionary["firstName"] as? String,
            let lastName = dictionary["lastName"] as? String,
            let email = dictionary["email"] as? String,
            let birthdayString = dictionary["birthday"] as? String,
            let joinDateString = dictionary["joinDate"] as? String,
            let roleString = dictionary["role"] as? String,
            let role = ProfileRole(rawValue: roleString),
            let isAdmin = dictionary["isAdmin"] as? Bool,
            let birthday = formatter.date(from: birthdayString)
        else {
            print("Missing or invalid required fields")
            return nil
        }
        
        // Assign optional fields with default values if necessary.
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
        self.isAdmin = isAdmin
    }
    
    /// Initializes a `Profile` instance with explicit parameters.
    /// - Parameters:
    ///   - id: Unique identifier for the profile.
    ///   - primaryHospitalId: Primary hospital ID.
    ///   - musterId: Muster ID.
    ///   - firstName: First name.
    ///   - lastName: Last name.
    ///   - email: Email address.
    ///   - birthday: Birthday date.
    ///   - joinDate: Join date as a string.
    ///   - role: User role.
    ///   - isAdmin: Administrative status.
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
    
    /// Initializes a `Profile` instance with default values.
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
    
    // MARK: - Computed Properties
    
    /// Converts the profile data into a dictionary suitable for Firestore.
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
    
    // MARK: - Coding Keys
    
    /// Specifies the coding keys for encoding and decoding.
    private enum CodingKeys: String, CodingKey {
        case id, primaryHospitalId, musterId, firstName, lastName, email, birthday, joinDate, role, isAdmin
    }
    
    // MARK: - Hashable Conformance
    
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
