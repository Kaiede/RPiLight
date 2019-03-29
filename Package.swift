// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RPiLight",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "RPiLight",
            targets: ["RPiLight"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Kaiede/Ephemeris.git", from: "1.0.0"),
        .package(url: "https://github.com/kareman/Moderator.git", from: "0.5.0"),
        .package(url: "https://github.com/Kaiede/PCA9685.git", from: "3.0.0"),
        .package(url: "https://github.com/Kaiede/MCP4725.git", from: "0.1.0"),
        .package(url: "https://github.com/Kaiede/SingleBoard.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RPiLight",
            dependencies: ["Service", "Moderator"]),
        .target(
            name: "Service",
            dependencies: ["LED", "Logging", "Ephemeris"]),
        .target(
            name: "LED",
            dependencies: ["Logging", "MCP4725", "PCA9685", "SingleBoard"]),
        .target(name: "Logging"),

        // Test Targets
        .testTarget(
            name: "ServiceTests",
            dependencies: ["Service"]
        )
    ]
)
