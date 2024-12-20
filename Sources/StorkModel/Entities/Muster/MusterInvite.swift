//
//  MusterInvite.swift
//
//
//  Created by Nick Molargik on 12/10/24.
//

import Foundation

public struct MusterInvite: Identifiable, Codable, Hashable {
    public var id: String
    public var recipientId: String
    public var recipientName: String
    public var senderName: String
    public var musterName: String
    public var musterId: String
    public var primaryHospitalName: String
    public var message: String
    public var primaryColor: String
    
    public var dictionary: [String: Any] {
        return [
            "recipientId": recipientId,
            "recipientName": recipientName,
            "senderName": senderName,
            "musterName": musterName,
            "musterId": musterId,
            "primaryHospitalName": primaryHospitalName,
            "message": message,
            "primaryColor": primaryColor
        ]
    }

    public init?(from dictionary: [String: Any], id: String?) {
        guard
            let id = id,
            let recipientId = dictionary["recipientId"] as? String,
            let recipientName = dictionary["recipientName"] as? String,
            let senderName = dictionary["senderName"] as? String,
            let musterName = dictionary["musterName"] as? String,
            let musterId = dictionary["musterId"] as? String,
            let primaryHospitalName = dictionary["primaryHospitalName"] as? String,
            let message = dictionary["message"] as? String,
            let primaryColor = dictionary["primaryColor"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.senderName = senderName
        self.musterName = musterName
        self.musterId = musterId
        self.primaryHospitalName = primaryHospitalName
        self.message = message
        self.primaryColor = primaryColor
    }

    public init(
        id: String,
        recipientId: String,
        recipientName: String,
        senderName: String,
        musterName: String,
        musterId: String,
        primaryHospitalName: String,
        message: String,
        primaryColor: String
    ) {
        self.id = id
        self.recipientId = recipientId
        self.recipientName = recipientName
        self.senderName = senderName
        self.musterName = musterName
        self.musterId = musterId
        self.primaryHospitalName = primaryHospitalName
        self.message = message
        self.primaryColor = primaryColor
    }
}
