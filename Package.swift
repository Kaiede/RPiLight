// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "RPiLight",
    targets: [
    	Target(
    		name: "RPiLight",
    		dependencies: ["PWM", "Logging"]
    	),
    	Target(
            name: "PWM",
            dependencies: ["Logging"]
        ),
        Target(name: "Logging")
    ],
    dependencies: [
        .Package(url: "https://github.com/Kaiede/SwiftyGPIO.git", majorVersion: 1),
        .Package(url: "https://github.com/Kaiede/Moderator.git", majorVersion: 0),
        .Package(url: "https://github.com/Kaiede/PCA9685.git", majorVersion:1),
    ],
    swiftLanguageVersions: [3, 4]
)
