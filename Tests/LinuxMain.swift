import XCTest
@testable import ServiceTests
@testable import LEDTests

// swiftlint:disable trailing_comma

XCTMain([
    // LED Tests
    testCase(ChannelTests.allTests),
    testCase(ModuleTests.allTests),
    testCase(TypeTests.allTests),
    // Service Tests
    testCase(BehaviorTests.allTests),
    testCase(ChannelControllerTests.allTests),
    testCase(DayTimeTests.allTests),
    testCase(EventTests.allTests),
    testCase(LayerTests.allTests),
    testCase(LightControllerTests.allTests),
    testCase(ScheduleDescriptionTests.allTests),
    testCase(ServiceDescriptionTests.allTests),
    testCase(SwiftExtensionsTests.allTests),
])
