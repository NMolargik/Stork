//
//  ProEnvironment.swift
//  StorkDesignSystem
//
//  Environment plumbing for Stork Pro gating. Feature views read `isProUnlocked` to decide
//  what to show and call `requestProUpgrade(feature)` when a locked feature is tapped; the
//  composition root sets both and presents the paywall from its stable root (a sheet
//  presented from deep inside a list row or tab accessory can be torn down with it).
//

import SwiftUI
import StorkCore

/// Asks the composition root to present the Stork Pro paywall for `feature`.
public struct ProUpgradeRequest {
    private let handler: @MainActor (ProFeature) -> Void

    public init(_ handler: @escaping @MainActor (ProFeature) -> Void) {
        self.handler = handler
    }

    @MainActor
    public func callAsFunction(_ feature: ProFeature) {
        handler(feature)
    }
}

public extension EnvironmentValues {
    /// True when every Stork Pro feature is available (purchase, Family Sharing, or grandfathered).
    @Entry var isProUnlocked: Bool = false

    /// Presents the paywall for a feature. Defaults to a no-op so previews and tests don't crash.
    @Entry var requestProUpgrade: ProUpgradeRequest = ProUpgradeRequest { _ in }
}
