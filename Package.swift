// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "RPiLight",
    targets: [
    	Target(
    		name: "RPiLight",
    		dependencies: ["PWM"]
    	),
    	Target(
            name: "PWM",
            dependencies: ["PCA9685"]
        ),
        Target(name: "PCA9685")
    ],
    dependencies: [
        .Package(url: "https://github.com/Kaiede/SwiftyGPIO.git", majorVersion: 1),
    ]
)
