// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "RPiLight",
    targets: [
    	Target(
    		name: "RPiLight",
    		dependencies: ["PWM"]
    	),
    	Target(name: "PWM")
    ],
    dependencies: [
        .Package(url: "https://github.com/Kaiede/SwiftyGPIO.git", majorVersion: 1),
    ]
)
