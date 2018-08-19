import XCTest
@testable import CoreTests

XCTMain([
    testCase(SwiftExtensionsTests.allTests),
    testCase(BehaviorTests.allTests),
    testCase(ChannelControllerTests.allTests),
    testCase(ConfigurationTests.allTests),
    testCase(LayerTests.allTests),
    testCase(LightControllerTests.allTests)
])
