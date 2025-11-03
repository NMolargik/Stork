//
//  AuthError.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import Foundation

enum AuthError: Error, LocalizedError {
    case loginFailed(String)
    case reauthenticationFailed(String)
    case updateFailed(String)
    case deletionFailed(String)
    case passwordResetFailed(String)
    case signOutFailed(String)
    
    var message: String {
        switch self {
        case .loginFailed(let msg),
             .reauthenticationFailed(let msg),
             .updateFailed(let msg),
             .deletionFailed(let msg),
             .passwordResetFailed(let msg),
             .signOutFailed(let msg):
            return msg
        }
    }

    var errorDescription: String? { message }
}
