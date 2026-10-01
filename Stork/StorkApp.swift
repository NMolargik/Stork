//
//  StorkApp.swift
//  Stork
//
//  The thin @main entry point. Builds the `SessionController` composition root (injecting
//  the app-side Spotlight indexer), registers it for App Intents, and hosts `RootView`
//  from the StorkComposition package. All architecture lives in `Packages/Stork`.
//

import SwiftUI
import AppIntents
import TipKit
import StorkCore
import StorkComposition

@main
struct StorkApp: App {
    @UIApplicationDelegateAdaptor(QuickActionAppDelegate.self) private var appDelegate
    @State private var quickActions = QuickActionRelay.shared

    @State private var session: SessionController
    @State private var router = AppRouter()

    init() {
        let session = SessionController(indexer: SpotlightDeliveryIndexer())
        _session = State(initialValue: session)

        // Expose the session to App Intents (@Dependency) so Siri/Shortcuts can
        // log deliveries and read stats through the same use-cases.
        AppDependencyManager.shared.add(dependency: session)

        try? Tips.configure([.displayFrequency(.immediate)])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(router)
                .onOpenURL { url in
                    if let link = DeepLink(url: url) { router.open(link) }
                }
                .task { consumeQuickAction() }
                .onChange(of: quickActions.url) { _, _ in consumeQuickAction() }
        }
        .commands {
            StorkCommands(router: router, session: session)
        }
    }

    private func consumeQuickAction() {
        guard let url = quickActions.url else { return }
        quickActions.url = nil
        if let link = DeepLink(url: url) { router.open(link) }
    }
}
