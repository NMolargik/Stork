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
    public let importDeliveries: any ImportDeliveries
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

    // MARK: Privacy lock

    public let appLock: AppLockController

    // MARK: Environmental managers

    /// Owned only so `weatherManager` can take a one-shot when-in-use fix while the user
    /// logs a delivery. Nothing else reads location.
    public let locationManager: LocationManager
    public let weatherManager: WeatherManager
    public let cloudSyncManager: CloudSyncManager
    #if canImport(HealthKit) && !os(visionOS)
    public let healthManager: HealthManager
    #endif

    // MARK: Stork Pro

    /// StoreKit 2 purchase/grandfather state; also the `EntitlementProviding` every
    /// feature view model is handed.
    public let storeManager: StoreManager
    public var entitlement: any EntitlementProviding { storeManager }

    private let milestoneShareReview: MilestoneShareReviewPolicy

    /// Call when a career-milestone share card was actually shared; prompts for a review
    /// the first time only.
    public func noteMilestoneCardShared() {
        milestoneShareReview.milestoneCardShared()
    }

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
            #if DEBUG
            container = try StorkStore.makeContainer(inMemory: inMemory || DebugLaunchOptions.inMemoryStore)
            #else
            container = try StorkStore.makeContainer(inMemory: inMemory)
            #endif
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
        importDeliveries = ImportDeliveriesUseCase(repository: deliveries)
        updateDelivery = UpdateDeliveryUseCase(repository: deliveries)
        deleteDelivery = DeleteDeliveryUseCase(repository: deliveries)
        deleteAllDeliveries = DeleteAllDeliveriesUseCase(repository: deliveries)
        loadCareerTotals = LoadCareerTotalsUseCase(repository: deliveries)

        loadTags = LoadTagsUseCase(repository: tagRepository)
        saveTag = SaveTagUseCase(repository: tagRepository)
        deleteTag = DeleteTagUseCase(repository: tagRepository)

        appLock = AppLockController()

        let location = LocationManager()
        locationManager = location
        weatherManager = WeatherManager(locationProvider: location)

        storeManager = StoreManager()
        milestoneShareReview = MilestoneShareReviewPolicy(storage: UserDefaults.standard, requester: reviewRequester)
        #if canImport(HealthKit) && !os(visionOS)
        healthManager = HealthManager()
        #endif

        let cloudSync = CloudSyncManager()
        cloudSyncManager = cloudSync

        // CloudKit imports feed the same change stream as local writes, so screens
        // refresh from one signal (background sync, no blocking screen).
        cloudSync.configure(with: container.mainContext)
        cloudSync.onRemoteChange = { changes.notify() }

        #if DEBUG
        // `-StorkSeedWrapSample 1`: two years of sample births for verifying the Year Wrap.
        if DebugLaunchOptions.seedWrapSample, ((try? loadDeliveries()) ?? []).isEmpty {
            // Straight into the context: skips the review prompt and milestone side effects.
            for delivery in DebugSampleBirths.twoYears() { container.mainContext.insert(delivery) }
            try? container.mainContext.save()
        }
        if DebugLaunchOptions.seedPastBirths, ((try? loadDeliveries()) ?? []).isEmpty {
            let years = PastBirths.years(from: 2018, to: 2022, average: 140)
            let splits = PastBirthsSplits(multiplesPercent: 3, lossesPercent: 1, boysPercent: 51)
            for delivery in PastBirths.makeDeliveries(years: years, splits: splits, role: .primaryNurse) { container.mainContext.insert(delivery) }
            try? container.mainContext.save()
        }
        #endif
    }
}
