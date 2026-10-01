// swift-tools-version: 6.2
import PackageDescription

// The Stork umbrella package: layered, single-responsibility modules that the thin
// app target (and the widget/watch extensions) compose. Dependencies point inward —
// features depend on the design system and core; data implements core's protocols;
// core depends on nothing. The macOS floor exists only so `swift test` runs on the
// host; the app ships iOS/watchOS-only.

let package = Package(
    name: "Stork",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v26)],

    // products = what the app and extensions can `import`
    products: [
        .library(name: "StorkCore",                 targets: ["StorkCore"]),
        .library(name: "StorkData",                 targets: ["StorkData"]),
        .library(name: "StorkDesignSystem",         targets: ["StorkDesignSystem"]),
        .library(name: "StorkServices",             targets: ["StorkServices"]),
        .library(name: "StorkFeatureDeliveries",    targets: ["StorkFeatureDeliveries"]),
        .library(name: "StorkFeatureDashboard",     targets: ["StorkFeatureDashboard"]),
        .library(name: "StorkFeatureOnboarding",    targets: ["StorkFeatureOnboarding"]),
        .library(name: "StorkFeatureSettings",      targets: ["StorkFeatureSettings"]),
        .library(name: "StorkFeatureExport",        targets: ["StorkFeatureExport"]),
        .library(name: "StorkComposition",          targets: ["StorkComposition"]),
    ],

    // targets = modules; the folder under Sources/ must match each target name.
    // Approachable concurrency: every module defaults to the MainActor, matching the
    // app's SWIFT_DEFAULT_ACTOR_ISOLATION setting. Pure helpers opt out with `nonisolated`.
    targets: [
        .target(
            name: "StorkCore",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkData",
            dependencies: ["StorkCore"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkDesignSystem",
            dependencies: ["StorkCore"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkServices",
            dependencies: ["StorkCore"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkFeatureDeliveries",
            dependencies: ["StorkCore", "StorkDesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkFeatureDashboard",
            dependencies: ["StorkCore", "StorkDesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkFeatureOnboarding",
            dependencies: ["StorkCore", "StorkDesignSystem", "StorkServices"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkFeatureSettings",
            dependencies: ["StorkCore", "StorkDesignSystem", "StorkServices"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkFeatureExport",
            dependencies: ["StorkCore", "StorkDesignSystem"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .target(
            name: "StorkComposition",
            dependencies: ["StorkCore", "StorkData", "StorkServices", "StorkDesignSystem", "StorkFeatureDeliveries", "StorkFeatureDashboard", "StorkFeatureOnboarding", "StorkFeatureSettings", "StorkFeatureExport"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),

        .testTarget(
            name: "StorkCoreTests",
            dependencies: ["StorkCore"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "StorkDataTests",
            dependencies: ["StorkData"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "StorkServicesTests",
            dependencies: ["StorkServices"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "StorkFeatureExportTests",
            dependencies: ["StorkFeatureExport"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "StorkFeatureDeliveriesTests",
            dependencies: ["StorkFeatureDeliveries"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "StorkFeatureDashboardTests",
            dependencies: ["StorkFeatureDashboard"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "StorkFeatureSettingsTests",
            dependencies: ["StorkFeatureSettings"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
    ]
)
