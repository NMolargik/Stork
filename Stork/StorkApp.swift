//
//  StorkApp.swift
//  Stork
//
//  Created by Nick Molargik on 9/28/25.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct StorkApp: App {
    private let sharedModelContainer: ModelContainer

    init() {
        let cloudKitContainerID = "iCloud.com.molargiksoftware.Stork"

        do {
            let config = ModelConfiguration(
                cloudKitDatabase: .private(cloudKitContainerID)
            )

            sharedModelContainer = try ModelContainer(
                for: Delivery.self, Baby.self, DeliveryTag.self,
                configurations: config
            )
        } catch {
            fatalError("[Stork] Failed to initialize ModelContainer: \(error)")
        }

        // Configure TipKit
        try? Tips.configure([
            .displayFrequency(.immediate)
        ])
    }

    @State private var pendingDeepLink: DeepLink?

    var body: some Scene {
        WindowGroup {
            ContentView(pendingDeepLink: $pendingDeepLink)
                .modelContainer(sharedModelContainer)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "stork" else { return }

        switch url.host {
        case "new-delivery":
            pendingDeepLink = .newDelivery
        case "dashboard":
            pendingDeepLink = .dashboard
        case "deliveries":
            if url.pathComponents.contains("week") {
                pendingDeepLink = .weeklyDeliveries
            } else {
                pendingDeepLink = .deliveries
            }
        default:
            break
        }
    }
}
