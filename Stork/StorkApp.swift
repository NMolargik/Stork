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
    @AppStorage(AppStorageKeys.useDayMonthYearDates) private var useDayMonthYearDates: Bool = false
    @AppStorage(AppStorageKeys.useMetricUnits) private var useMetricUnits: Bool = false
    @AppStorage(AppStorageKeys.isOnboardingComplete) private var isOnboardingComplete: Bool = false

    @State private var userManager: UserManager
    
    private let sharedModelContainer: ModelContainer

    init() {
        let cloudKitContainerID = "iCloud.com.molargiksoftware.Stork"

        do {
            let config = ModelConfiguration(
                cloudKitDatabase: .private(cloudKitContainerID)
            )

            sharedModelContainer = try ModelContainer(
                for: User.self, Delivery.self, Baby.self, DeliveryTag.self,
                configurations: config
            )

            userManager = UserManager(context: sharedModelContainer.mainContext)
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
            ContentView(resetApplication: self.resetApplication, pendingDeepLink: $pendingDeepLink)
                .modelContainer(sharedModelContainer)
                .environment(userManager)
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
        case "home":
            pendingDeepLink = .home
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
    
    private func resetApplication() {
        useMetricUnits = false
        useDayMonthYearDates = false
        isOnboardingComplete = false
    }
}
