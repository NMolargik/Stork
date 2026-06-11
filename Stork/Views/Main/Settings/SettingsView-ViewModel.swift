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
        // Network state
        private var networkMonitor: NWPathMonitor?
        var isOnline: Bool = true

        // App metadata
        var appVersion: String {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
            let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "—"
            return "\(version) (Build \(build))"
        }

        // Lifecycle
        func startNetworkMonitoring() {
            let monitor = NWPathMonitor()
            // @Sendable: NWPathMonitor invokes this on its background queue.
            monitor.pathUpdateHandler = { @Sendable [weak self] path in
                let isOnline = (path.status == .satisfied)
                Task { @MainActor in
                    self?.isOnline = isOnline
                }
            }
            monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
            self.networkMonitor = monitor
        }

        func stopNetworkMonitoring() {
            networkMonitor?.cancel()
            networkMonitor = nil
        }
    }
}
