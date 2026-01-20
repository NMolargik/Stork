//
//  DeliveryError.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

enum DeliveryError: Error, LocalizedError {
    case notFound(String)
    case limitReached(String)
    case creationFailed(String)
    case updateFailed(String)
    case fetchFailed(String)
    case deletionFailed(String)

    var message: String {
        switch self {
        case .notFound(let msg),
             .limitReached(let msg),
             .creationFailed(let msg),
             .updateFailed(let msg),
             .fetchFailed(let msg),
             .deletionFailed(let msg):
            return msg
        }
    }

    var errorDescription: String? { message }
}
