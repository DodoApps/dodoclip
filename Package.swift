// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DodoClip",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DodoClip",
            targets: ["DodoClip"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DodoClip",
            dependencies: [],
            path: "Sources/DodoClip",
            resources: [
                .process("Resources/Assets.xcassets")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "DodoClipTests",
            dependencies: ["DodoClip"],
            path: "Tests/DodoClipTests"
        )
    ]
)
