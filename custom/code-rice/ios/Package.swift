// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "code-rice-ios",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .executable(name: "code-rice-ios", targets: ["code-rice-ios"])
    ],
    dependencies: [
        // Add dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "code-rice-ios",
            dependencies: []
        )
    ]
)





