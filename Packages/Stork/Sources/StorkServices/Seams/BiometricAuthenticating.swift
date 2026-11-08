//
//  BiometricAuthenticating.swift
//  StorkServices
//
//  The seam over LocalAuthentication so the lock logic is testable without a device.
//

import Foundation
import LocalAuthentication

public enum BiometricKind: Sendable { case faceID, touchID, opticID, none }

public enum AuthenticationResult: Sendable, Equatable {
    case success
    case cancelled
    case failed
    /// The device has no passcode or biometrics set up, so it cannot authenticate at all.
    case unavailable
}

@MainActor
public protocol BiometricAuthenticating {
    /// Whether the device can authenticate (biometrics or passcode).
    var isAvailable: Bool { get }
    var biometricKind: BiometricKind { get }
    func authenticate(reason: String) async -> AuthenticationResult
}

#if !os(watchOS)
/// `LAPolicy.deviceOwnerAuthentication`: Face ID / Touch ID, falling back to the device
/// passcode. Nothing is stored; the system does the matching.
@MainActor
public struct LocalAuthenticator: BiometricAuthenticating {
    public init() {}

    public var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    public var biometricKind: BiometricKind {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .none
        }
    }

    public func authenticate(reason: String) async -> AuthenticationResult {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return .unavailable }
        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            return ok ? .success : .failed
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel: return .cancelled
            case .passcodeNotSet, .biometryNotAvailable: return .unavailable
            default: return .failed
            }
        } catch {
            return .failed
        }
    }
}
#endif
