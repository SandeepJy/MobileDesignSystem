// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileDesignSystem",
    platforms: [
        .iOS(.v15)
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
