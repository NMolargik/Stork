//
//  PersistenceError.swift
//  StorkCore
//
//  The typed failure domain for the persistence boundary. Repositories and use-cases
//  declare `throws(PersistenceError)` (SCOUT's typed-throws idiom), so view models catch
//  a concrete, exhaustive error instead of `any Error` — and tests can match on cases.
//

import Foundation

nonisolated public enum PersistenceError: Error, Equatable, LocalizedError {
    /// Reading from the store failed.
    case fetchFailed(String)
    /// Persisting a change failed.
    case saveFailed(String)

    public var errorDescription: String? {
        // Resolves in `Bundle.main` at runtime — translations live in the app target's
        // `Localizable.xcstrings` (see the localization policy in CLAUDE.md).
        switch self {
        case .fetchFailed(let detail): String(localized: "Couldn't load your deliveries. (\(detail))", bundle: .module)
        case .saveFailed(let detail): String(localized: "Couldn't save your changes. (\(detail))", bundle: .module)
        }
    }
}
