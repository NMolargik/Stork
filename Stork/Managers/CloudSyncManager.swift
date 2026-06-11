//
//  CloudSyncManager.swift
//  Stork
//
//  Created by Nick Molargik on 1/17/26.
//

import Foundation
import SwiftData
import CoreData
import Network

/// Manages and monitors iCloud/CloudKit sync status for SwiftData
@MainActor @Observable
final class CloudSyncManager {

    // MARK: - Sync Status

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced(Date)
        case error(String)
        case offline

        var displayText: String {
            switch self {
            case .idle:
                return "Ready"
            case .syncing:
                return "Syncing..."
            case .synced(let date):
                return "Last synced \(date.formatted(.relative(presentation: .named)))"
            case .error(let message):
                return "Error: \(message)"
            case .offline:
                return "Offline"
            }
        }

        var systemImage: String {
            switch self {
            case .idle:
                return "icloud"
            case .syncing:
                return "arrow.triangle.2.circlepath.icloud"
            case .synced:
                return "checkmark.icloud"
            case .error:
                return "exclamationmark.icloud"
            case .offline:
                return "icloud.slash"
            }
        }

        var color: String {
            switch self {
            case .idle:
                return "secondary"
            case .syncing:
                return "blue"
            case .synced:
                return "green"
            case .error:
                return "red"
            case .offline:
                return "orange"
            }
        }
    }

    // MARK: - Properties

    private(set) var syncStatus: SyncStatus = .idle
    private(set) var isSyncing: Bool = false
    private(set) var lastSyncDate: Date?
    private(set) var hasReceivedRemoteChange: Bool = false

    /// Invoked on the main actor whenever CloudKit reports a remote change,
    /// so the app can refresh in-memory caches mid-session.
    var onRemoteChange: (() -> Void)?

    private var modelContext: ModelContext?
    private var networkMonitor: NWPathMonitor?
    private var isNetworkAvailable: Bool = true
    private var notificationObservers: [Any] = []

    // MARK: - Initialization

    init() {}

    func configure(with context: ModelContext) {
        self.modelContext = context
        startMonitoring()
    }

    func cleanup() {
        stopMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // Monitor network status
        let monitor = NWPathMonitor()
        // @Sendable: NWPathMonitor invokes this on its background queue.
        monitor.pathUpdateHandler = { @Sendable [weak self] path in
            let isAvailable = path.status == .satisfied
            Task { @MainActor in
                self?.handleNetworkChange(isAvailable: isAvailable)
            }
        }
        monitor.start(queue: DispatchQueue(label: "CloudSyncNetworkMonitor"))
        self.networkMonitor = monitor

        // Monitor CloudKit sync events
        let remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleRemoteChange()
            }
        }
        notificationObservers.append(remoteChangeObserver)

        // Monitor import/export events from CloudKit
        let importObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSPersistentStoreCoordinatorStoresDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleStoreChange()
            }
        }
        notificationObservers.append(importObserver)

        // Set initial status
        updateSyncStatus()
    }

    private func stopMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil

        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
    }

    // MARK: - Event Handlers

    private func handleNetworkChange(isAvailable: Bool) {
        isNetworkAvailable = isAvailable
        updateSyncStatus()
    }

    private func handleRemoteChange() {
        lastSyncDate = Date()
        hasReceivedRemoteChange = true
        updateSyncStatus()
        onRemoteChange?()
    }

    private func handleStoreChange() {
        lastSyncDate = Date()
        updateSyncStatus()
    }

    private func updateSyncStatus() {
        if !isNetworkAvailable {
            syncStatus = .offline
        } else if isSyncing {
            syncStatus = .syncing
        } else if let lastSync = lastSyncDate {
            syncStatus = .synced(lastSync)
        } else {
            syncStatus = .idle
        }
    }

    // MARK: - Manual Sync

    /// Triggers a manual sync by saving the context and refreshing
    func triggerSync() async {
        guard isNetworkAvailable else {
            syncStatus = .offline
            return
        }

        guard let context = modelContext else {
            syncStatus = .error("Not configured")
            return
        }

        isSyncing = true
        syncStatus = .syncing

        do {
            // Save any pending changes to trigger sync
            if context.hasChanges {
                try context.save()
            }

            // Small delay to allow CloudKit sync to initiate
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Mark sync as complete
            lastSyncDate = Date()
            isSyncing = false
            syncStatus = .synced(lastSyncDate!)

        } catch {
            isSyncing = false
            syncStatus = .error(error.localizedDescription)
        }
    }

    /// Checks if iCloud is available on this device
    var isCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
