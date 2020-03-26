// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RPiLight",
    platforms: [.macOS(.v10_14)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "RPiLight",
            targets: ["RPiLight"]),
    ],
    dependencies: [
        // External Dependencies
        .package(url: "https://github.com/kareman/Moderator.git", from: "0.5.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/Kaiede/swift-nio-mqtt.git", .branch("nio-ssl")),
        
        // Internal Dependencies
        .package(url: "https://github.com/Kaiede/Ephemeris.git", from: "1.0.2"),
        .package(url: "https://github.com/Kaiede/PCA9685.git", from: "3.0.0"),
        .package(url: "https://github.com/Kaiede/MCP4725.git", from: "0.1.0"),
        .package(url: "https://github.com/Kaiede/SingleBoard.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RPiLight",
            dependencies: ["Service", "Moderator", "NIOMQTTClient"]),
        .target(
            name: "Service",
            dependencies: ["LED", "Logging", "Ephemeris", "Yams"]),
        .target(
            name: "LED",
            dependencies: ["Logging", "MCP4725", "PCA9685", "SingleBoard"]),

        // Test Targets
        .testTarget(
            name: "ServiceTests",
            dependencies: ["Service"]
        ),
        .testTarget(
            name: "LEDTests",
            dependencies: ["LED"]
        )
    ]
)
