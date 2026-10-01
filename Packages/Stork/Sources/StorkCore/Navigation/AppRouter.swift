//
//  AppRouter.swift
//  StorkCore
//
//  App-wide navigation state injected through the environment. Owns the selected tab
//  and a pending deep link the active screen consumes. The composition root and menu
//  commands drive it; features read it.
//

import Foundation
import Observation

@MainActor
@Observable
public final class AppRouter {
    /// The currently selected tab in the adaptive `TabView`.
    public var selectedTab: AppTab = .dashboard

    /// A deep link awaiting handling by the main UI (e.g. "open new delivery").
    /// Set by widgets / quick actions / Siri; cleared once consumed.
    public var pendingDeepLink: DeepLink?

    public init() {}

    /// Selects a tab directly (menu commands, keyboard shortcuts).
    public func select(_ tab: AppTab) {
        selectedTab = tab
    }

    /// Routes a deep link: jumps to its destination tab and stores it for the
    /// screen to act on (e.g. presenting new-delivery entry).
    public func open(_ link: DeepLink) {
        if let tab = link.destinationTab {
            selectedTab = tab
        }
        pendingDeepLink = link
    }
}
