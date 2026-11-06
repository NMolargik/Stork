//
//  EntitlementProviding.swift
//  StorkCore
//
//  Seam over the Stork Pro purchase state so feature gating is testable without
//  StoreKit. `StoreManager` (StorkServices) is the production conformance; tests
//  substitute an in-memory fake. Nothing in Core decides *how* Pro was unlocked
//  (purchase, Family Sharing, or the pre-3.0 paid-app grandfather) — only whether it is.
//

import Foundation

@MainActor
public protocol EntitlementProviding: AnyObject {
    /// True when every Stork Pro feature should be available.
    var isProUnlocked: Bool { get }
}
