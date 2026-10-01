//
//  SessionController.swift
//  StorkComposition
//
//  The composition root: the one place that wires concrete `StorkData` / `StorkServices`
//  implementations into the `StorkCore` protocols, owns the app-wide managers, and vends
//  the per-screen view models the feature modules inject. The thin `@main` app holds a
//  single `SessionController` and does only the App-Intents / UIKit-delegate glue on top.
//
//  App-specific seams that depend on app-target types (the Spotlight indexer needs the
//  App Intents `DeliveryEntity`) are injected in; everything else has a production default.
//

import Foundation
import SwiftData
import StorkCore
import StorkData
import StorkServices

@MainActor
@Observable
public final class SessionController {

    // MARK: Persistence

    public let container: ModelContainer

    // MARK: Repositories

    public let deliveryRepository: any DeliveryRepository
    public let tagRepository: any TagRepository

    // MARK: Delivery use cases

    public let loadDeliveries: any LoadDeliveries
    public let logDelivery: any LogDelivery
    public let updateDelivery: any UpdateDelivery
    public let deleteDelivery: any DeleteDelivery
    public let deleteAllDeliveries: any DeleteAllDeliveries
    public let loadCareerTotals: any LoadCareerTotals

    /// Yields whenever the delivery store changes (local writes, Siri logs, CloudKit
    /// imports). Screens observe this instead of registering callbacks on the session.
    public let observeDeliveryChanges: any ObserveDeliveryChanges

    private let deliveryChanges: DeliveryChangeCenter

    /// Nudges every observing screen to reload (menu-bar "Refresh Deliveries").
    public func requestRefresh() {
        deliveryChanges.notify()
    }

    // MARK: Tag use cases

    public let loadTags: any LoadTags
    public let saveTag: any SaveTag
    public let deleteTag: any DeleteTag

    // MARK: Environmental managers

    public let locationManager: LocationManager
    public let weatherManager: WeatherManager
    public let cloudSyncManager: CloudSyncManager
    #if canImport(HealthKit) && !os(visionOS)
    public let healthManager: HealthManager
    #endif

    /// Triggers a manual iCloud sync (exposed so the app's menu commands needn't import
    /// the services layer directly).
    public func syncNow() async {
        await cloudSyncManager.triggerSync()
    }

    // MARK: Init

    /// Builds the whole dependency graph.
    ///
    /// - Parameters:
    ///   - inMemory: Use an in-memory store (tests / previews) instead of CloudKit.
    ///   - indexer: App-provided Spotlight indexer (needs the app's `DeliveryEntity`).
    ///   - reviewRequester: Defaults to the StoreKit-backed requester.
    public init(
        inMemory: Bool = false,
        indexer: (any DeliveryIndexing)? = nil,
        reviewRequester: (any ReviewRequesting)? = AppStoreReviewRequester()
    ) {
        do {
            container = try StorkStore.makeContainer(inMemory: inMemory)
        } catch {
            fatalError("[Stork] Failed to open the local store: \(error)")
        }

        // One multicast change signal: the repository notifies it on every local write
        // and CloudKit notifies it on remote imports.
        let changes = DeliveryChangeCenter()
        deliveryChanges = changes
        observeDeliveryChanges = ObserveDeliveryChangesUseCase(center: changes)

        let deliveries = DefaultDeliveryRepository(
            container: container,
            indexer: indexer,
            reviewRequester: reviewRequester,
            changeCenter: changes
        )
        deliveryRepository = deliveries
        tagRepository = DefaultTagRepository(container: container)

        loadDeliveries = LoadDeliveriesUseCase(repository: deliveries)
        logDelivery = LogDeliveryUseCase(repository: deliveries)
        updateDelivery = UpdateDeliveryUseCase(repository: deliveries)
        deleteDelivery = DeleteDeliveryUseCase(repository: deliveries)
        deleteAllDeliveries = DeleteAllDeliveriesUseCase(repository: deliveries)
        loadCareerTotals = LoadCareerTotalsUseCase(repository: deliveries)

        loadTags = LoadTagsUseCase(repository: tagRepository)
        saveTag = SaveTagUseCase(repository: tagRepository)
        deleteTag = DeleteTagUseCase(repository: tagRepository)

        let location = LocationManager()
        locationManager = location
        weatherManager = WeatherManager(locationProvider: location)
        #if canImport(HealthKit) && !os(visionOS)
        healthManager = HealthManager()
        #endif

        let cloudSync = CloudSyncManager()
        cloudSyncManager = cloudSync

        // CloudKit imports feed the same change stream as local writes, so screens
        // refresh from one signal (background sync, no blocking screen).
        cloudSync.configure(with: container.mainContext)
        cloudSync.onRemoteChange = { changes.notify() }
    }
}
