//
//  AppLockController.swift
//  StorkServices
//
//  The optional privacy lock (free for everyone). When enabled it locks on launch and
//  after the app has been in the background longer than the user's grace period, and
//  unlocks with Face ID (or Touch ID) with a device-passcode fallback. If the device
//  cannot authenticate at all it never traps the user out: it stays unlocked.
//

#if !os(watchOS)
import Foundation
import Observation
import StorkCore
import os

@MainActor
@Observable
public final class AppLockController {

    public private(set) var isEnabled: Bool
    public private(set) var isLocked: Bool
    public private(set) var isAuthenticating = false
    /// Set when the last attempt failed; shown on the lock screen.
    public private(set) var lastFailure: AuthenticationResult?

    private let authenticator: any BiometricAuthenticating
    private let defaults: UserDefaults
    private let now: () -> Date
    private var backgroundedAt: Date?

    public init(
        authenticator: any BiometricAuthenticating = LocalAuthenticator(),
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = { Date() }
    ) {
        self.authenticator = authenticator
        self.defaults = defaults
        self.now = now
        let enabled = defaults.bool(forKey: AppStorageKeys.requireBiometricLock)
        isEnabled = enabled
        isLocked = enabled   // a cold launch always starts locked
    }

    public var biometricKind: BiometricKind { authenticator.biometricKind }
    public var isDeviceAuthAvailable: Bool { authenticator.isAvailable }

    /// Seconds the app may sit in the background before re-locking.
    public var timeoutSeconds: Int {
        AppLockPolicy.normalizedTimeout(defaults.object(forKey: AppStorageKeys.lockTimeoutSeconds) as? Int)
    }

    /// Re-reads the toggle after Settings flips the `@AppStorage` value directly.
    public func syncEnabledFromDefaults() {
        let stored = defaults.bool(forKey: AppStorageKeys.requireBiometricLock)
        if stored != isEnabled {
            isEnabled = stored
            if !stored { isLocked = false }
        }
    }

    // MARK: - Scene lifecycle

    public func sceneDidEnterBackground() {
        guard isEnabled, !isLocked else { return }
        backgroundedAt = now()
    }

    /// Call when the scene becomes active. Locks if the grace period passed; the system
    /// Face ID sheet itself only makes the scene inactive, never backgrounded, so it
    /// cannot re-lock the app by accident.
    public func sceneDidBecomeActive() {
        defer { backgroundedAt = nil }
        guard let backgroundedAt else { return }
        if AppLockPolicy.shouldLock(isEnabled: isEnabled, backgroundedAt: backgroundedAt, now: now(), timeout: timeoutSeconds) {
            isLocked = true
        }
    }

    // MARK: - Unlocking

    public func unlock(reason: String) async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let result = await authenticator.authenticate(reason: reason)
        switch result {
        case .success, .unavailable:
            // Without any device authentication a lock would only strand the user.
            isLocked = false
            lastFailure = nil
        case .cancelled, .failed:
            lastFailure = result
        }
    }

    // MARK: - Turning it on or off

    /// Turning the lock on or off requires authenticating once, so the feature is proven
    /// to work before it can lock you out, and a borrowed unlocked phone cannot switch it off.
    /// Returns whether the change was made.
    @discardableResult
    public func setEnabled(_ on: Bool, reason: String) async -> Bool {
        guard on != isEnabled else { return true }
        guard authenticator.isAvailable else {
            lastFailure = .unavailable
            return false
        }
        let result = await authenticator.authenticate(reason: reason)
        guard result == .success else {
            lastFailure = result
            return false
        }
        lastFailure = nil
        isEnabled = on
        defaults.set(on, forKey: AppStorageKeys.requireBiometricLock)
        if on { backgroundedAt = nil } else { isLocked = false }
        return true
    }
}
#endif
