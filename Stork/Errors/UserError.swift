//
//  UserError.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

enum UserError: Error, LocalizedError {
    case creationFailed(String)
    case updateFailed(String)
    case fetchFailed(String)
    case listFailed(String)
    case deletionFailed(String)
    
    var message: String {
        switch self {
        case .creationFailed(let msg),
             .updateFailed(let msg),
             .fetchFailed(let msg),
             .listFailed(let msg),
             .deletionFailed(let msg):
            return msg
        }
    }

    var errorDescription: String? { message }
}
