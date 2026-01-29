// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FiveStarSupport",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "FiveStarSupport",
            targets: ["FiveStarSupport"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FiveStarSupport",
            dependencies: []),
    ]
)
