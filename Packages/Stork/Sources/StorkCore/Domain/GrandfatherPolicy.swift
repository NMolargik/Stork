//
//  GrandfatherPolicy.swift
//  StorkCore
//
//  Stork was a paid-up-front app before 3.0; anyone who bought it keeps every Pro feature
//  for life. The signal is the App Store's `AppTransaction`; this is the pure decision so
//  it is unit-tested without StoreKit.
//
//  `AppTransaction.originalAppVersion` is the **build number** (`CFBundleVersion`) on iOS,
//  not the marketing version. Every paid-era build shipped with a build number below
//  `firstFreeBuild` (the 2.x releases used 1 through the 50s), and 3.0 — the first free
//  build — ships as build 300, so "original build < 300" identifies paid buyers. Outside
//  production (Xcode, sandbox, TestFlight) StoreKit reports a placeholder like "1.0" that
//  would grandfather every tester, so only production transactions qualify.
//

import Foundation

nonisolated public enum GrandfatherPolicy {

    /// The first build released as free-with-Pro (3.0). All later builds must stay ≥ 300.
    public static let firstFreeBuild = "300"
    /// The marketing version that went free; used when StoreKit hands back a dotted version.
    public static let firstFreeMarketingVersion = "3.0"

    /// Whether an `AppTransaction` describes a paid (pre-3.0) purchase.
    ///
    /// - Parameters:
    ///   - originalAppVersion: `AppTransaction.originalAppVersion` — a bare build number
    ///     on iOS ("41"), or a dotted version on macOS ("2.4").
    ///   - isProduction: `AppTransaction.environment == .production`.
    public static func qualifies(originalAppVersion: String, isProduction: Bool) -> Bool {
        guard isProduction else { return false }
        return predatesFreeRelease(originalAppVersion)
    }

    /// Whether the version string belongs to the paid-up-front era. Bare integers are
    /// build numbers and compare against `firstFreeBuild`; dotted strings compare against
    /// `firstFreeMarketingVersion`.
    public static func predatesFreeRelease(_ version: String) -> Bool {
        let trimmed = version.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = VersionNumber(trimmed) else { return false }
        let threshold = trimmed.contains(".") ? firstFreeMarketingVersion : firstFreeBuild
        guard let cutoff = VersionNumber(threshold) else { return false }
        return components < cutoff
    }
}

/// Dotted numeric version comparison ("2.4.1" < "3.0", "53" < "300"). Trailing zeros are
/// insignificant, so "3.0" and "3.0.0" are equal.
nonisolated public struct VersionNumber: Comparable, Sendable {
    public let components: [Int]

    public init?(_ string: String) {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { return nil }
        var components: [Int] = []
        for part in parts {
            guard let value = Int(part), value >= 0 else { return nil }
            components.append(value)
        }
        self.components = components
    }

    public static func < (lhs: VersionNumber, rhs: VersionNumber) -> Bool {
        compare(lhs, rhs) == .orderedAscending
    }

    public static func == (lhs: VersionNumber, rhs: VersionNumber) -> Bool {
        compare(lhs, rhs) == .orderedSame
    }

    private static func compare(_ lhs: VersionNumber, _ rhs: VersionNumber) -> ComparisonResult {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }
}
