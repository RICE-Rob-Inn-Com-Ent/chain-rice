// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TaskFlowPro",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TaskFlowPro", targets: ["TaskFlowPro"]),
        .library(name: "TaskFlowCore", targets: ["TaskFlowCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.45.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.1"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.3.0"),
        .package(url: "https://github.com/danielgindi/Charts.git", from: "4.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "TaskFlowPro",
            dependencies: [
                "TaskFlowCore",
                "Alamofire",
                "RealmSwift",
                "Kingfisher",
                "SwiftyJSON",
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "DGCharts", package: "Charts")
            ],
            path: "Sources/TaskFlowPro"
        ),
        .target(
            name: "TaskFlowCore",
            dependencies: [
                "Alamofire",
                "RealmSwift",
                "SwiftyJSON"
            ],
            path: "Sources/TaskFlowCore"
        ),
        .testTarget(
            name: "TaskFlowProTests",
            dependencies: ["TaskFlowPro", "TaskFlowCore"],
            path: "Tests/TaskFlowProTests"
        )
    ]
)


