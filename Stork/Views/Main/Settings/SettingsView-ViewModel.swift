//
//  SettingsView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 11/3/25.
//

import Foundation
import Network

extension SettingsView {
    @Observable
    class ViewModel {
        // UI state
        var editingUser: Bool = false
        var showSignOutConfirmation: Bool = false
        var showDeleteConfirmation: Bool = false
        var showingFarewell: Bool = false
        var pendingProfileImageData: Data? = nil

        // Network state
        private var networkMonitor: NWPathMonitor?
        var isOnline: Bool = true

        // App metadata
        var appVersion: String {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
            let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "—"
            return "\(version) (Build \(build))"
        }
        var bundleIdentifier: String { Bundle.main.bundleIdentifier ?? "—" }

        // Lifecycle
        func startNetworkMonitoring() {
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { [weak self] path in
                DispatchQueue.main.async {
                    self?.isOnline = (path.status == .satisfied)
                }
            }
            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor.start(queue: queue)
            self.networkMonitor = monitor
        }

        func stopNetworkMonitoring() {
            networkMonitor?.cancel()
            networkMonitor = nil
        }
    }
}
