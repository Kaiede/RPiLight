import XCTest
import Logging
@testable import LEDTests
@testable import NetworkTests
@testable import ServiceTests

Log.setLoggingLevel(.warn)

XCTMain([
    // LED Tests
    testCase(ChannelTests.allTests),
    testCase(ModuleTests.allTests),
    // Network Tests
    testCase(EndpointTests.allTests),
    testCase(MosquittoTests.allTests),
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
