//
//  StorkShortcuts.swift
//  Stork
//
//  App Shortcuts surface Stork's intents to Siri and Spotlight with zero
//  user setup, and give Apple Intelligence invocable capability.
//

import AppIntents

struct StorkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDeliveryIntent(),
            phrases: [
                "Log a delivery in \(.applicationName)",
                "Add a delivery to \(.applicationName)",
                "Record a delivery in \(.applicationName)"
            ],
            shortTitle: "Log Delivery",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: BabiesThisWeekIntent(),
            phrases: [
                "How many babies this week in \(.applicationName)",
                "Show my week in \(.applicationName)",
                "\(.applicationName) weekly count"
            ],
            shortTitle: "Babies This Week",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: CareerTotalsIntent(),
            phrases: [
                "What are my career totals in \(.applicationName)",
                "How many babies have I delivered in \(.applicationName)"
            ],
            shortTitle: "Career Totals",
            systemImageName: "trophy.fill"
        )

        AppShortcut(
            intent: StartDeliveryEntryIntent(),
            phrases: [
                "Start a new delivery in \(.applicationName)",
                "Open delivery entry in \(.applicationName)"
            ],
            shortTitle: "New Delivery",
            systemImageName: "square.and.pencil"
        )
    }
}
