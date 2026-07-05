//
//  StorkCommands.swift
//  Stork
//
//  Menu bar commands for iPadOS and Mac. New Delivery is the hero action; navigation and
//  data commands route through `AppRouter` and the `SessionController`.
//

import SwiftUI
import StorkCore
import StorkComposition

@MainActor
struct StorkCommands: Commands {
    let router: AppRouter
    let session: SessionController

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button {
                router.open(.newDelivery)
            } label: {
                Label("New Delivery", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandMenu("Go") {
            Button("Dashboard") { router.open(.dashboard) }.keyboardShortcut("1", modifiers: .command)
            Button("Deliveries") { router.open(.deliveries) }.keyboardShortcut("2", modifiers: .command)
            Button("Calendar") { router.open(.calendar) }.keyboardShortcut("3", modifiers: .command)
            Divider()
            Button("Settings") { router.open(.settings) }.keyboardShortcut(",", modifiers: .command)
        }

        CommandMenu("Data") {
            Button("Sync with iCloud") {
                Task {
                    await session.syncNow()
                    session.requestRefresh()
                }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Button("Refresh Deliveries") {
                session.requestRefresh()
            }
        }
    }
}
