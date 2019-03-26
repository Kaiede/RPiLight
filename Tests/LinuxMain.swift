import XCTest
import Logging
@testable import ServiceTests

Log.setLoggingLevel(.warn)

XCTMain([
    testCase(SwiftExtensionsTests.allTests),
    testCase(BehaviorTests.allTests),
    testCase(ChannelControllerTests.allTests),
    testCase(EventTests.allTests),
    testCase(LayerTests.allTests),
    testCase(LightControllerTests.allTests),
    testCase(ServiceConfigTests.allTests),
    testCase(ScheduleConfigTests.allTests),
])
