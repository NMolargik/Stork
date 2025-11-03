//
//  HospitalError.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

enum HospitalError: Error, LocalizedError {
    case notFound(String)
    case creationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    
    var message: String {
        switch self {
        case .notFound(let msg),
             .creationFailed(let msg),
             .updateFailed(let msg),
             .deletionFailed(let msg):
            return msg
        }
    }

    var errorDescription: String? { message }
}
