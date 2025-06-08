// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
//
//  Package
//
//  Created by Nick Molargik on 11/4/24.
//

import PackageDescription

let package = Package(
    name: "skipapp-stork",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .macCatalyst(.v16)
    ],
    products: [
        .library(
            name: "StorkApp",
            type: .dynamic,
            targets: ["Stork"]
        ),
        .library(
            name: "StorkModel",
            type: .dynamic,
            targets: ["StorkModel"]
        )
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.5.22"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.29.3"),
        .package(url: "https://source.skip.tools/skip-kit.git", from: "0.5.0"),
        .package(url: "https://source.skip.tools/skip-firebase.git", from: "0.9.0"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.3.6"),
        .package(url: "https://source.skip.tools/skip-model.git", from: "1.5.0"),
        .package(url: "https://github.com/aduryagin/skip-revenuecat.git", from: "0.0.12"),
    ],
    targets: [
        .target(
            name: "Stork",
            dependencies: [
                "StorkModel",
                .product(name: "SkipUI", package: "skip-ui"),
                .product(name: "SkipModel", package: "skip-model"),
                .product(name: "SkipKit", package: "skip-kit"),
                .product(name: "SkipRevenueCat", package: "skip-revenuecat")
                
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .testTarget(
            name: "StorkTests",
            dependencies: [
                "Stork",
                .product(name: "SkipTest", package: "skip"),
                .product(name: "SkipUI", package: "skip-ui"),
                .product(name: "SkipModel", package: "skip-model"),
                .product(name: "SkipKit", package: "skip-kit"),
                .product(name: "SkipRevenueCat", package: "skip-revenuecat")
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .target(
            name: "StorkModel",
            dependencies: [
                .product(name: "SkipFoundation", package: "skip-foundation"),
                .product(name: "SkipModel", package: "skip-model"),
                .product(name: "SkipFirebaseFirestore", package: "skip-firebase"),
                .product(name: "SkipUI", package: "skip-ui"),
                .product(name: "SkipFirebaseAuth", package: "skip-firebase"),
                .product(name: "SkipFirebaseStorage", package: "skip-firebase")
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        ),
        .testTarget(
            name: "StorkModelTests",
            dependencies: [
                "StorkModel",
                .product(name: "SkipTest", package: "skip")
            ],
            resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]
        )
    ]
)
