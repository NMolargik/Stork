# Stork UX2: Steps pill on Dashboard only, "Optional" past-birth fields

Simulator: iPhone 18 Pro, iOS 27.2, in-memory store with the debug seeds. Screens were reached with temporary, uncommitted launch-argument hooks (open tab, show Add Past Births) that are not in the commit.

| Screen | Before | After |
|---|---|---|
| Settings | before-settings.png (pill covers the iCloud row) | after-settings.png (no pill) |
| Deliveries | before-deliveries.png (pill covers the last card) | after-deliveries.png (no pill) |
| Calendar | before-calendar.png | after-calendar.png (no pill) |
| Dashboard | before-dashboard.png | after-dashboard.png (pill still shown; "Connect Health" because the simulator has no Health data) |
| Add Past Births, empty | before-pastbirths-empty.png ("Skip %") | after-pastbirths-empty.png ("Optional") |
| Add Past Births, with values | before-pastbirths-value.png | after-pastbirths-value.png ("%" appears only after a number is typed) |

Not verified on screen: scrolling the Dashboard to its end (the system adds the accessory's height to the scroll safe area).
