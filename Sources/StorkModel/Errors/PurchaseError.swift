//
//  PurchaseError.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 1/16/25.
//

import Foundation

public enum PurchaseError: Error, LocalizedError {
    case purchaseLogInError(String)

    public var errorDescription: String? {
        switch self {
        case .purchaseLogInError(let message):
            return "Purchase error \(message)"
        }
    }
}
