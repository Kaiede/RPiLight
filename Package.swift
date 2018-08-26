// swift-tools-version:3.1

import PackageDescription

//
// Backport of Package(url:from:)
//
extension Package.Dependency {
	public class func Package(url: String, from versionString: String) -> Package.Dependency {
		guard let version = Version(versionString) else { fatalError() }
		let nextMajor = Version(version.major + 1, 0, 0)
		return Package(url: url, versions: version..<nextMajor)
	}
}

//
// Package
//
let package = Package(
    name: "RPiLight",
    targets: [
    	Target(
    		name: "RPiLight",
    		dependencies: ["Core"]
    	),
	Target(
		name: "Core",
		dependencies: ["PWM", "Logging"]
	),
    	Target(
            name: "PWM",
            dependencies: ["Logging"]
        ),
        Target(name: "Logging")
    ],
    dependencies: [
        .Package(url: "https://github.com/Kaiede/Ephemeris.git", from: "1.0.0"),
        .Package(url: "https://github.com/kareman/Moderator.git", from: "0.5.0"),
        .Package(url: "https://github.com/Kaiede/PCA9685.git", from: "1.0.0"),
        .Package(url: "https://github.com/Kaiede/SwiftyGPIO.git", from: "1.0.9")
    ],
    swiftLanguageVersions: [3, 4]
)
