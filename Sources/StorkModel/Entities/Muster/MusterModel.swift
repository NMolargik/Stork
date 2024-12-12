//
//  MusterModel.swift
//
//
//  Created by Nick Molargik on 11/26/24.
//

import Foundation

public struct Muster: Identifiable, Codable, Hashable {
    public var id: String
    public var profileIds: [String]
    public var primaryHospitalId: String
    public var administratorProfileIds: [String]
    public var name: String
    public var primaryColor: String

    var dictionary: [String: Any] {
        return [
            "profileIds": profileIds,
            "primaryHospitalId": primaryHospitalId,
            "administratorProfileIds": administratorProfileIds,
            "name": name,
            "primaryColor": primaryColor,
        ]
    }

    public init?(from dictionary: [String: Any], id: String?) {
        guard
            let id = id,
            let profileIds = dictionary["profileIds"] as? [String],
            let primaryHospitalId = dictionary["primaryHospitalId"] as? String,
            let administratorProfileIds = dictionary["administratorProfileIds"] as? [String],
            let name = dictionary["name"] as? String,
            let primaryColor = dictionary["primaryColor"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.profileIds = profileIds
        self.primaryHospitalId = primaryHospitalId
        self.administratorProfileIds = administratorProfileIds
        self.name = name
        self.primaryColor = primaryColor
    }

    public init(
        id: String, 
        profileIds: [String],
        primaryHospitalId: String,
        administratorProfileIds: [String],
        name: String,
        primaryColor: String
    ) {
        self.id = id
        self.profileIds = profileIds
        self.primaryHospitalId = primaryHospitalId
        self.administratorProfileIds = administratorProfileIds
        self.name = name
        self.primaryColor = primaryColor
    }
}
