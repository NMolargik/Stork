//
//  AppLockPolicy.swift
//  StorkCore
//
//  When the optional privacy lock should engage. Pure: given whether the lock is on, how
//  long the app was away and the user's chosen grace period, decide. The system prompt
//  (Face ID with a passcode fallback) lives in StorkServices behind a seam.
//

import Foundation

nonisolated public enum AppLockPolicy {

    /// Grace periods offered in Settings, in seconds. 0 locks the moment the app leaves
    /// the foreground.
    public static let timeoutOptions: [Int] = [0, 60, 300, 900]
    public static let defaultTimeout = 60

    /// A cold launch always locks (when enabled). After a trip to the background it
    /// locks once `timeout` seconds have passed.
    public static func shouldLock(
        isEnabled: Bool,
        backgroundedAt: Date?,
        now: Date,
        timeout: Int
    ) -> Bool {
        guard isEnabled else { return false }
        guard let backgroundedAt else { return true }   // no timestamp = fresh launch
        return now.timeIntervalSince(backgroundedAt) >= TimeInterval(max(0, timeout))
    }

    /// A stored timeout that is not one of the options falls back to the default.
    public static func normalizedTimeout(_ stored: Int?) -> Int {
        guard let stored, timeoutOptions.contains(stored) else { return defaultTimeout }
        return stored
    }
}
