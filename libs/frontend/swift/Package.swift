// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftFrontend",
    platforms: [
        .iOS(.v16), .macOS(.v13)
    ],
    dependencies: [
        // --- Стан і архітектура ---
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.10.0"),

        // --- UI-компоненти та анімації ---
        .package(url: "https://github.com/SVGKit/SVGKit.git", from: "3.0.0"), // SVG
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0"), // Lottie
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", from: "0.1.0"), // Розширення SwiftUI
        .package(url: "https://github.com/ivanvorobei/SPAlert.git", from: "5.0.0"), // Красиві алерти та тости

        // --- Темізація та шрифти ---
        .package(url: "https://github.com/Rightpoint/BonMot.git", from: "6.0.0"), // Типографія
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.11.0"), // Зображення з кешем

        // --- Графіки та візуалізація ---
        .package(url: "https://github.com/AppPear/ChartView.git", from: "1.6.5"), // Простий UI для графіків

        // --- Мережі та API ---
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.1"), // Мережі

        // --- Локалізація та утиліти ---
        .package(url: "https://github.com/marmelroy/Localize-Swift.git", from: "3.2.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.7.1") // Якщо треба шифрування
    ],
    targets: [
        .target(
            name: "SwiftFrontend",
            dependencies: [
                "swift-composable-architecture",
                "SVGKit",
                "lottie-ios",
                "SwiftUIX",
                "SPAlert",
                "BonMot",
                "Kingfisher",
                "ChartView",
                "Alamofire",
                "Localize-Swift",
                "CryptoSwift"
            ],
            path: "Sources"
        )
    ]
)
