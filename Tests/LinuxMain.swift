import XCTest
@testable import CoreTests

XCTMain([
    testCase(SwiftExtensionsTests.allTests),
    testCase(ChannelControllerTests.allTests),
    testCase(LayerTests.allTests)
])
