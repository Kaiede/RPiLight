import XCTest
@testable import ServiceTests
@testable import LEDTests

// swiftlint:disable trailing_comma

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
