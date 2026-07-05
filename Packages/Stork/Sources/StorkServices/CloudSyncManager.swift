//
//  CloudSyncManager.swift
//  StorkData
//
//  Monitors iCloud/CloudKit sync status for SwiftData and surfaces remote changes so the
//  app can refresh in-memory caches mid-session (no blocking sync screen).
//

import Foundation
import SwiftData
import CoreData
import Network

@MainActor
@Observable
public final class CloudSyncManager {

    // MARK: - Sync status

    public enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced(Date)
        case error(String)
        case offline

        public var displayText: String {
            switch self {
            case .idle: String(localized: "Ready", bundle: .module)
            case .syncing: String(localized: "Syncing...", bundle: .module)
            case .synced(let date): String(localized: "Last synced \(date.formatted(.relative(presentation: .named)))", bundle: .module)
            case .error(let message): String(localized: "Error: \(message)", bundle: .module)
            case .offline: String(localized: "Offline", bundle: .module)
            }
        }

        public var systemImage: String {
            switch self {
            case .idle: "icloud"
            case .syncing: "arrow.triangle.2.circlepath.icloud"
            case .synced: "checkmark.icloud"
            case .error: "exclamationmark.icloud"
            case .offline: "icloud.slash"
            }
        }

        public var color: String {
            switch self {
            case .idle: "secondary"
            case .syncing: "blue"
            case .synced: "green"
            case .error: "red"
            case .offline: "orange"
            }
        }
    }

    // MARK: - Properties

    public private(set) var syncStatus: SyncStatus = .idle
    public private(set) var isSyncing: Bool = false
    public private(set) var lastSyncDate: Date?
    public private(set) var hasReceivedRemoteChange: Bool = false

    /// Invoked on the main actor whenever CloudKit reports a remote change.
    public var onRemoteChange: (() -> Void)?

    private var modelContext: ModelContext?
    private var networkMonitor: NWPathMonitor?
    private var isNetworkAvailable: Bool = true
    private var notificationObservers: [Any] = []

    public init() {}

    public func configure(with context: ModelContext) {
        self.modelContext = context
        startMonitoring()
    }

    public func cleanup() {
        stopMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { @Sendable [weak self] path in
            let isAvailable = path.status == .satisfied
            Task { @MainActor in self?.handleNetworkChange(isAvailable: isAvailable) }
        }
        monitor.start(queue: DispatchQueue(label: "CloudSyncNetworkMonitor"))
        self.networkMonitor = monitor

        let remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleRemoteChange() }
        }
        notificationObservers.append(remoteChangeObserver)

        let importObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSPersistentStoreCoordinatorStoresDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleStoreChange() }
        }
        notificationObservers.append(importObserver)

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

    // MARK: - Event handlers

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

    // MARK: - Manual sync

    /// Triggers a manual sync by saving the context and refreshing.
    public func triggerSync() async {
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
            if context.hasChanges { try context.save() }
            try await Task.sleep(nanoseconds: 500_000_000)
            lastSyncDate = Date()
            isSyncing = false
            syncStatus = .synced(lastSyncDate!)
        } catch {
            isSyncing = false
            syncStatus = .error(error.localizedDescription)
        }
    }

    /// Whether iCloud is available on this device.
    public var isCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
