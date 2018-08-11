// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "RPiLight",
    swiftLanguageVersions: [3, 4],
    targets: [
    	Target(
    		name: "RPiLight",
    		dependencies: ["PWM", "Logging"]
    	),
    	Target(
            name: "PWM",
            dependencies: ["PCA9685", "Logging"]
        ),
        Target(name: "PCA9685"),
        Target(name: "Logging")
    ],
    dependencies: [
        .Package(url: "https://github.com/Kaiede/SwiftyGPIO.git", majorVersion: 1),
        .Package(url: "https://github.com/Kaiede/Moderator.git", majorVersion: 0),
    ]
)
