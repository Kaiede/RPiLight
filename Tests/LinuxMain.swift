import XCTest
import Logging
@testable import ServiceTests
@testable import LEDTests

Log.setLoggingLevel(.warn)

XCTMain([
    // LED Tests
    testCase(ChannelTests.allTests),
    testCase(ModuleTests.allTests),
    // Service Tests
    testCase(SwiftExtensionsTests.allTests),
    testCase(BehaviorTests.allTests),
    testCase(ChannelControllerTests.allTests),
    testCase(EventTests.allTests),
    testCase(LayerTests.allTests),
    testCase(LightControllerTests.allTests),
    testCase(ServiceConfigTests.allTests),
    testCase(ScheduleConfigTests.allTests),
])
