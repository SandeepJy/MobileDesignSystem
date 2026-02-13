// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileDesignSystem",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MobileDesignSystem",
            targets: ["MobileDesignSystem"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MobileDesignSystem",
            dependencies: []),
        .testTarget(
            name: "MobileDesignSystemTests",
            dependencies: ["MobileDesignSystem"]),
    ]
)
