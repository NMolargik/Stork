//
//  AppLockControllerTests.swift
//  StorkServicesTests
//

import Testing
import Foundation
import StorkCore
@testable import StorkServices

@MainActor
private final class FakeAuthenticator: BiometricAuthenticating {
    var isAvailable = true
    var biometricKind: BiometricKind = .faceID
    var result: AuthenticationResult = .success
    private(set) var prompts = 0
    func authenticate(reason: String) async -> AuthenticationResult { prompts += 1; return result }
}

@MainActor
private final class Clock { var now = Date(timeIntervalSince1970: 1_000_000) }

@MainActor
private func make(enabled: Bool, timeout: Int? = nil, auth: FakeAuthenticator = FakeAuthenticator(), clock: Clock = Clock()) -> (AppLockController, FakeAuthenticator, Clock) {
    let defaults = UserDefaults(suiteName: "applock-\(UUID().uuidString)")!
    defaults.set(enabled, forKey: AppStorageKeys.requireBiometricLock)
    if let timeout { defaults.set(timeout, forKey: AppStorageKeys.lockTimeoutSeconds) }
    return (AppLockController(authenticator: auth, defaults: defaults, now: { clock.now }), auth, clock)
}

@Suite("AppLockController")
@MainActor
struct AppLockControllerTests {

    @Test("Starts locked on a cold launch only when enabled")
    func coldLaunch() {
        #expect(make(enabled: true).0.isLocked)
        #expect(!make(enabled: false).0.isLocked)
    }

    @Test("A successful unlock opens the app; a failure keeps it locked")
    func unlock() async {
        let (lock, auth, _) = make(enabled: true)
        auth.result = .failed
        await lock.unlock(reason: "x")
        #expect(lock.isLocked && lock.lastFailure == .failed)
        auth.result = .success
        await lock.unlock(reason: "x")
        #expect(!lock.isLocked)
    }

    @Test("Re-locks only after the grace period in the background")
    func grace() async {
        let (lock, _, clock) = make(enabled: true, timeout: 60)
        await lock.unlock(reason: "x")
        lock.sceneDidEnterBackground()
        clock.now.addTimeInterval(30)
        lock.sceneDidBecomeActive()
        #expect(!lock.isLocked)
        lock.sceneDidEnterBackground()
        clock.now.addTimeInterval(61)
        lock.sceneDidBecomeActive()
        #expect(lock.isLocked)
    }

    @Test("The system prompt (inactive then active, never backgrounded) does not re-lock")
    func promptDoesNotRelock() async {
        let (lock, _, clock) = make(enabled: true, timeout: 0)
        await lock.unlock(reason: "x")
        clock.now.addTimeInterval(500)
        lock.sceneDidBecomeActive()
        #expect(!lock.isLocked)
    }

    @Test("Immediate timeout locks on every return")
    func immediate() async {
        let (lock, _, _) = make(enabled: true, timeout: 0)
        await lock.unlock(reason: "x")
        lock.sceneDidEnterBackground()
        lock.sceneDidBecomeActive()
        #expect(lock.isLocked)
    }

    @Test("Enabling needs a successful authentication; failure leaves it off")
    func enabling() async {
        let (lock, auth, _) = make(enabled: false)
        auth.result = .cancelled
        #expect(await lock.setEnabled(true, reason: "x") == false)
        #expect(!lock.isEnabled)
        auth.result = .success
        #expect(await lock.setEnabled(true, reason: "x"))
        #expect(lock.isEnabled && !lock.isLocked)
    }

    @Test("A device with no passcode cannot enable the lock, and never strands the user")
    func unavailable() async {
        let auth = FakeAuthenticator()
        auth.isAvailable = false
        let (lock, _, _) = make(enabled: false, auth: auth)
        #expect(await lock.setEnabled(true, reason: "x") == false)
        #expect(lock.lastFailure == .unavailable)

        let (stranded, auth2, _) = make(enabled: true)
        auth2.result = .unavailable
        await stranded.unlock(reason: "x")
        #expect(!stranded.isLocked)
    }

    @Test("Disabling also needs authentication and unlocks")
    func disabling() async {
        let (lock, auth, _) = make(enabled: true)
        await lock.unlock(reason: "x")
        auth.result = .failed
        #expect(await lock.setEnabled(false, reason: "x") == false)
        #expect(lock.isEnabled)
        auth.result = .success
        #expect(await lock.setEnabled(false, reason: "x"))
        #expect(!lock.isEnabled && !lock.isLocked)
    }

    @Test("Unknown stored timeouts fall back to the default")
    func timeout() {
        #expect(make(enabled: true).0.timeoutSeconds == AppLockPolicy.defaultTimeout)
        #expect(make(enabled: true, timeout: 300).0.timeoutSeconds == 300)
        #expect(make(enabled: true, timeout: 0).0.timeoutSeconds == 0)
    }
}
