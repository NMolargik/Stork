// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription

let package = Package(
    name: "skipapp-stork",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "StorkApp", type: .dynamic, targets: ["Stork"]),
        .library(name: "StorkModel", type: .dynamic, targets: ["StorkModel"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.2.18"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.18.0"),
        .package(url: "https://source.skip.tools/skip-kit.git", from: "0.1.5"),
        .package(url: "https://source.skip.tools/skip-firebase.git", branch: "main"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.2.3"),
        .package(url: "https://source.skip.tools/skip-model.git", from: "1.4.0"),
        .package(url: "https://github.com/aduryagin/skip-revenuecat.git", from: "0.0.10"),
        .package(url: "https://github.com/RevenueCat/purchases-hybrid-common.git", exact: "13.3.0")
    ],
    targets: [
        .target(name: "Stork", dependencies: ["StorkModel", .product(name: "SkipUI", package: "skip-ui"), .product(name: "SkipModel", package: "skip-model"), .product(name: "SkipKit", package: "skip-kit"), .product(name: "SkipFirebaseMessaging", package: "skip-firebase"), .product(name: "SkipRevenueCat", package: "skip-revenuecat"), .product(name: "SkipFirebaseStorage", package: "skip-firebase")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "StorkTests", dependencies: ["Stork", .product(name: "SkipTest", package: "skip")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "StorkModel", dependencies: [.product(name: "SkipFoundation", package: "skip-foundation"), .product(name: "SkipModel", package: "skip-model"), .product(name: "SkipFirebaseFirestore", package: "skip-firebase"), .product(name: "SkipUI", package: "skip-ui"), .product(name: "SkipFirebaseAuth", package: "skip-firebase"), .product(name: "SkipFirebaseStorage", package: "skip-firebase")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "StorkModelTests", dependencies: ["StorkModel", .product(name: "SkipTest", package: "skip")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
