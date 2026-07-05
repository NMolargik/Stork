//
//  WatchSession.swift
//  StorkWatch Watch App
//
//  The watch's composition root — a miniature of the iOS `SessionController`. Builds the
//  app-group CloudKit container through `StorkStore`, the repository (which runs the
//  shared save side effects: app-group fallback counts, complication reloads, milestone
//  detection), the use-cases the watch screens consume, and the change stream that
//  CloudKit imports feed.
//

import Foundation
import Observation
import SwiftData
import StorkCore
import StorkData
import StorkServices

@MainActor
@Observable
final class WatchSession {

    let loadDeliveries: any LoadDeliveries
    let logDelivery: any LogDelivery
    let observeDeliveryChanges: any ObserveDeliveryChanges

    let healthManager = HealthManager()

    /// Retained for the session: a `ModelContext` does not keep its container alive.
    private let container: ModelContainer
    private let cloudSyncManager: CloudSyncManager

    init() {
        do {
            container = try StorkStore.makeContainer(inAppGroup: true)
        } catch {
            fatalError("[StorkWatch] Failed to open the local store: \(error)")
        }

        let changes = DeliveryChangeCenter()
        observeDeliveryChanges = ObserveDeliveryChangesUseCase(center: changes)

        // No Spotlight indexer or review prompting on the watch; widget reloads and
        // app-group counts still run so complications stay current after watch saves.
        let repository = DefaultDeliveryRepository(
            container: container,
            changeCenter: changes
        )
        loadDeliveries = LoadDeliveriesUseCase(repository: repository)
        logDelivery = LogDeliveryUseCase(repository: repository)

        // CloudKit imports (deliveries logged on the phone) feed the same stream.
        let cloudSync = CloudSyncManager()
        cloudSync.configure(with: container.mainContext)
        cloudSync.onRemoteChange = { changes.notify() }
        cloudSyncManager = cloudSync
    }
}
