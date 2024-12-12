//
//  InvitationStatus.swift
//  
//
//  Created by Nick Molargik on 12/10/24.
//

import Foundation

public enum InvitationStatus: String, CaseIterable, Codable, Hashable {
    case pending
    case accepted
    case declined
    case cancelled

    public var description: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .cancelled:
            return "Cancelled"
        }
    }

    public var stringValue: String {
        self.description
    }
}
