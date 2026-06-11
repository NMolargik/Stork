//
//  StorkCommands.swift
//  Stork
//
//  Menu bar commands for iPadOS and Mac ("Designed for iPad").
//  Per current HIG, only standout actions carry icons — New Delivery is
//  the hero action; navigation and data commands stay text-only.
//

import SwiftUI

@MainActor
struct StorkCommands: Commands {
    @Binding var pendingDeepLink: DeepLink?

    let deliveryManager: DeliveryManager
    let cloudSyncManager: CloudSyncManager
    let toastManager: ToastManager

    var body: some Commands {
        // File > New Delivery (replaces the default New Item)
        CommandGroup(replacing: .newItem) {
            Button {
                pendingDeepLink = .newDelivery
            } label: {
                Label("New Delivery", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandMenu("Go") {
            Button("Dashboard") {
                pendingDeepLink = .dashboard
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Deliveries") {
                pendingDeepLink = .deliveries
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Calendar") {
                pendingDeepLink = .calendar
            }
            .keyboardShortcut("3", modifiers: .command)

            Divider()

            Button("Settings") {
                pendingDeepLink = .settings
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandMenu("Data") {
            Button("Sync with iCloud") {
                Task {
                    await cloudSyncManager.triggerSync()
                    await deliveryManager.refresh()
                    toastManager.show(message: "Synced with iCloud", style: .success, icon: "checkmark.icloud")
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Button("Refresh Deliveries") {
                Task {
                    await deliveryManager.refresh()
                }
            }
        }
    }
}
