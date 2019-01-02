import XCTest
import Logging
@testable import CoreTests

Log.setLoggingLevel(.warn)

XCTMain([
    testCase(SwiftExtensionsTests.allTests),
    testCase(BehaviorTests.allTests),
    testCase(ChannelControllerTests.allTests),
    testCase(ConfigurationTests.allTests),
    testCase(EventTests.allTests),
    testCase(LayerTests.allTests),
    testCase(LightControllerTests.allTests),
    testCase(ServiceConfigTests.allTests),
])
