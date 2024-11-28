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
        .library(name: "StorkAuth", type: .dynamic, targets: ["StorkAuth"]),
        .library(name: "StorkModel", type: .dynamic, targets: ["StorkModel"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.1.18"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-firebase.git", branch: "main"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-model.git", from: "1.0.0")
    ],
    targets: [
        .target(name: "Stork", dependencies: ["StorkAuth", .product(name: "SkipUI", package: "skip-ui"), .product(name: "SkipModel", package: "skip-model"), .product(name: "SkipFirebaseMessaging", package: "skip-firebase"), .product(name: "SkipFirebaseStorage", package: "skip-firebase")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "StorkTests", dependencies: ["Stork", .product(name: "SkipTest", package: "skip")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "StorkAuth", dependencies: ["StorkModel", .product(name: "SkipFirebaseAuth", package: "skip-firebase")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "StorkAuthTests", dependencies: ["StorkAuth", .product(name: "SkipTest", package: "skip")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "StorkModel", dependencies: [.product(name: "SkipFoundation", package: "skip-foundation"), .product(name: "SkipModel", package: "skip-model"), .product(name: "SkipFirebaseFirestore", package: "skip-firebase"), .product(name: "SkipUI", package: "skip-ui"), .product(name: "SkipFirebaseAuth", package: "skip-firebase"), .product(name: "SkipFirebaseStorage", package: "skip-firebase")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "StorkModelTests", dependencies: ["StorkModel", .product(name: "SkipTest", package: "skip")], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
