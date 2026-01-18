//
//  StorkWatchApp.swift
//  StorkWatch Watch App
//
//  Created by Nick Molargik on 1/17/26.
//

import SwiftUI
import SwiftData

@main
struct StorkWatchApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let cloudKitContainerID = "iCloud.com.molargiksoftware.Stork"
            let config = ModelConfiguration(
                groupContainer: .identifier(WatchAppGroup.id),
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            modelContainer = try ModelContainer(
                for: Delivery.self, Baby.self, DeliveryTag.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - Shared Constants
enum WatchAppGroup {
    static let id = "group.com.molargiksoftware.Stork"
}
