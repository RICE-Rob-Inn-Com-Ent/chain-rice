// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InfiniR",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "InfiniR",
            targets: ["InfiniR"]),
    ],
    dependencies: [
        // Import components from monorepo frontend
        .package(path: "../../../.frontend/ios")
    ],
    targets: [
        .target(
            name: "InfiniR",
            dependencies: []),
        .testTarget(
            name: "InfiniRTests",
            dependencies: ["InfiniR"]),
    ]
)
