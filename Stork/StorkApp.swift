//
//  StorkApp.swift
//  Stork
//

import SwiftUI
import SwiftData
import TipKit
import AppIntents

/// Composition root: builds the model container and every manager, then
/// injects them into the environment. Views never construct managers.
@main
struct StorkApp: App {
    @UIApplicationDelegateAdaptor(QuickActionAppDelegate.self) private var appDelegate
    @State private var quickActions = QuickActionRelay.shared

    private let sharedModelContainer: ModelContainer

    @State private var deliveryManager: DeliveryManager
    @State private var cloudSyncManager: CloudSyncManager
    @State private var locationManager: LocationManager
    @State private var weatherManager: WeatherManager
    @State private var exportManager: ExportManager
    @State private var toastManager: ToastManager
    #if !os(visionOS)
    @State private var healthManager: HealthManager
    #endif

    @State private var pendingDeepLink: DeepLink?

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

        let location = LocationManager()
        locationManager = location
        weatherManager = WeatherManager(locationProvider: location)

        let deliveries = DeliveryManager(container: sharedModelContainer)
        deliveryManager = deliveries

        // Sync runs in the background: refresh the in-memory cache whenever
        // CloudKit delivers remote changes (no blocking sync screen).
        let cloudSync = CloudSyncManager()
        cloudSync.configure(with: sharedModelContainer.mainContext)
        cloudSync.onRemoteChange = {
            Task { await deliveries.refresh() }
        }
        cloudSyncManager = cloudSync

        exportManager = ExportManager()
        toastManager = ToastManager()

        // Expose the delivery manager to App Intents (@Dependency) so Siri
        // and Shortcuts can log deliveries and read stats.
        AppDependencyManager.shared.add(dependency: deliveries)
        #if !os(visionOS)
        healthManager = HealthManager()
        #endif

        try? Tips.configure([
            .displayFrequency(.immediate)
        ])
    }

    private func consumeQuickAction() {
        guard let url = quickActions.url else { return }
        quickActions.url = nil
        if let link = DeepLink(url: url) {
            pendingDeepLink = link
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(pendingDeepLink: $pendingDeepLink)
                .toastContainer()
                .modelContainer(sharedModelContainer)
                .environment(deliveryManager)
                .environment(cloudSyncManager)
                .environment(locationManager)
                .environment(weatherManager)
                .environment(exportManager)
                .environment(toastManager)
                #if !os(visionOS)
                .environment(healthManager)
                #endif
                .onOpenURL { url in
                    if let link = DeepLink(url: url) {
                        pendingDeepLink = link
                    }
                }
                // Home Screen quick actions arrive via the UIKit delegates
                // and the relay; consume on launch (cold) and change (warm).
                .task {
                    consumeQuickAction()
                }
                .onChange(of: quickActions.url) { _, _ in
                    consumeQuickAction()
                }
        }
        .commands {
            StorkCommands(
                pendingDeepLink: $pendingDeepLink,
                deliveryManager: deliveryManager,
                cloudSyncManager: cloudSyncManager,
                toastManager: toastManager
            )
        }
    }
}
