//
//  StoreManager.swift
//  StorkServices
//
//  StoreKit 2 wrapper for the one-time Stork Pro unlock. Conforms to Core's
//  `EntitlementProviding` seam so gating logic tests with a fake instead of StoreKit.
//
//  Three roads to Pro, all collapsing into `isProUnlocked`:
//    1. A verified non-consumable transaction for `StorkProProduct.id` (own purchase or
//       Family Sharing).
//    2. Grandfathering: the app was paid before 3.0, so `AppTransaction` showing a pre-3.0
//       original purchase unlocks Pro for life (`GrandfatherPolicy`). Checked once and cached.
//    3. A cached result from a previous launch, so gating works offline and instantly.
//
//  The resolved state is mirrored into the app-group defaults for the widget extension.
//

import Foundation
import StoreKit
import Observation
import os
import StorkCore

@MainActor
@Observable
public final class StoreManager: EntitlementProviding {

    public private(set) var isLoading = false
    public private(set) var errorMessage: String?
    public private(set) var product: Product?

    /// A verified Stork Pro transaction exists (own purchase or Family Sharing).
    public private(set) var isPurchased: Bool
    /// The install predates the free 3.0 release — the user already paid for Stork.
    public private(set) var isGrandfathered: Bool

    /// One-time "thank you" for grandfathered users, shown by the composition root.
    public private(set) var shouldShowGrandfatherThankYou = false

    public var isProUnlocked: Bool { isPurchased || isGrandfathered }

    @ObservationIgnored private let defaults: any KeyValueStoring
    @ObservationIgnored private let sharedDefaults: (any KeyValueStoring)?
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    private let productID = StorkProProduct.id

    /// - Parameters:
    ///   - defaults: Entitlement cache (standard defaults in production).
    ///   - sharedDefaults: App-group defaults the widgets read; `nil` to skip mirroring.
    ///   - autoConfigure: Start product loading / entitlement refresh immediately.
    public init(
        defaults: any KeyValueStoring = UserDefaults.standard,
        sharedDefaults: (any KeyValueStoring)? = UserDefaults(suiteName: AppGroup.id),
        autoConfigure: Bool = true
    ) {
        self.defaults = defaults
        self.sharedDefaults = sharedDefaults
        isPurchased = defaults.bool(forKey: AppStorageKeys.proPurchased)
        isGrandfathered = defaults.bool(forKey: AppStorageKeys.proGrandfathered)
        mirrorToSharedDefaults()
        if autoConfigure {
            Task { await self.configure() }
        }
    }

    private func clearError() { errorMessage = nil }

    // MARK: - Setup and product loading

    public func configure() async {
        startObservingTransactionsIfNeeded()
        await loadProducts()
        await updateEntitlements()
        await checkGrandfatherIfNeeded()
    }

    private func loadProducts() async {
        isLoading = true
        clearError()
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            Log.app.error("Stork Pro product load failed: \(error.localizedDescription)")
            errorMessage = String(localized: "Couldn't load Stork Pro. Check your connection and try again.", bundle: .module)
        }
    }

    // MARK: - Purchase / Restore

    /// Starts the purchase flow. Returns true when Pro is unlocked as a result.
    public func purchase() async -> Bool {
        guard let product else {
            errorMessage = String(localized: "Stork Pro isn't available right now.", bundle: .module)
            return false
        }
        isLoading = true
        clearError()
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateEntitlements()
                await transaction.finish()
                return isProUnlocked
            case .userCancelled:
                return false
            case .pending:
                // Ask to Buy / SCA — the Transaction.updates listener finishes it later.
                return false
            @unknown default:
                return false
            }
        } catch {
            Log.app.error("Stork Pro purchase failed: \(error.localizedDescription)")
            errorMessage = String(localized: "Purchase failed: \(error.localizedDescription)", bundle: .module)
            return false
        }
    }

    /// Syncs with the App Store and re-reads entitlements (also re-runs the grandfather check).
    public func restore() async -> Bool {
        isLoading = true
        clearError()
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await updateEntitlements()
            await checkGrandfather(force: true)
            if !isProUnlocked {
                errorMessage = String(localized: "No Stork Pro purchase was found for this Apple Account.", bundle: .module)
            }
            return isProUnlocked
        } catch {
            Log.app.error("Stork Pro restore failed: \(error.localizedDescription)")
            errorMessage = String(localized: "Restore failed: \(error.localizedDescription)", bundle: .module)
            return false
        }
    }

    // MARK: - Entitlements

    private func updateEntitlements() async {
        var purchased = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                purchased = true
            }
        }
        setPurchased(purchased)
    }

    private func setPurchased(_ value: Bool) {
        isPurchased = value
        defaults.set(value, forKey: AppStorageKeys.proPurchased)
        mirrorToSharedDefaults()
    }

    private func startObservingTransactionsIfNeeded() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    if transaction.productID == self.productID {
                        await self.updateEntitlements()
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Grandfathering (paid app before 3.0)

    /// Runs the `AppTransaction` check once per install (the answer never changes), and
    /// retries on later launches only if it couldn't be determined (offline, no receipt).
    private func checkGrandfatherIfNeeded() async {
        guard !defaults.bool(forKey: AppStorageKeys.proGrandfatherChecked) else { return }
        await checkGrandfather(force: false)
    }

    private func checkGrandfather(force: Bool) async {
        do {
            let result = force ? try await AppTransaction.refresh() : try await AppTransaction.shared
            let transaction = try checkVerified(result)
            // Sandbox/TestFlight report a placeholder version ("1.0") that would grandfather
            // every tester; only a production receipt can qualify.
            let qualifies = GrandfatherPolicy.qualifies(
                originalAppVersion: transaction.originalAppVersion,
                isProduction: transaction.environment == .production
            )
            Log.app.info("Grandfather check: originalAppVersion=\(transaction.originalAppVersion, privacy: .public) environment=\(transaction.environment.rawValue, privacy: .public) qualifies=\(qualifies)")
            defaults.set(true, forKey: AppStorageKeys.proGrandfatherChecked)
            setGrandfathered(qualifies)
        } catch {
            // Leave the cached answer alone and try again next launch.
            Log.app.error("Grandfather check unavailable: \(error.localizedDescription)")
        }
    }

    private func setGrandfathered(_ value: Bool) {
        isGrandfathered = value
        defaults.set(value, forKey: AppStorageKeys.proGrandfathered)
        if value, !defaults.bool(forKey: AppStorageKeys.proGrandfatherThankYouShown) {
            shouldShowGrandfatherThankYou = true
        }
        mirrorToSharedDefaults()
    }

    /// The composition root calls this once the thank-you has been presented.
    public func markGrandfatherThankYouShown() {
        shouldShowGrandfatherThankYou = false
        defaults.set(true, forKey: AppStorageKeys.proGrandfatherThankYouShown)
    }

    // MARK: - Widgets

    private func mirrorToSharedDefaults() {
        sharedDefaults?.set(isProUnlocked, forKey: SharedDefaultsKey.isProUnlocked)
    }
}
