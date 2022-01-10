// swift-tools-version:5.1
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
        // External Dependencies
        .package(url: "https://github.com/kareman/Moderator.git", from: "0.5.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        // Internal Dependencies
        .package(url: "https://github.com/Kaiede/Ephemeris.git", from: "1.0.2"),
        .package(url: "https://github.com/Kaiede/SingleBoard.git", .branch("swift-revamp"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RPiLight",
            dependencies: [
                .target(name: "Service"),
                .product(name: "Moderator", package: "Moderator")
            ]
        ),
        .target(
            name: "Service",
            dependencies: [
                .target(name: "LED"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Ephemeris", package: "Ephemeris"),
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .target(
            name: "LED",
            dependencies: [.product(name: "Logging", package: "swift-log"),
                           .product(name: "MCP4725", package: "SingleBoard"),
                           .product(name: "PCA9685", package: "SingleBoard"),
                           .product(name: "SingleBoard", package: "SingleBoard")
                          ]
        ),

        // Test Targets
        .testTarget(
            name: "ServiceTests",
            dependencies: [
                .target(name: "Service")
            ]
        ),
        .testTarget(
            name: "LEDTests",
            dependencies: [
                .target(name: "LED")
            ]
        )
    ]
)
