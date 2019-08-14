/*
 RPiLight
 
 Copyright (c) 2018 Adam Thayer
 Licensed under the MIT license, as follows:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */

import XCTest
import Dispatch
@testable import Service

extension DispatchTimeInterval {
    func asMicroseconds() -> Int {
        switch self {
        case .seconds(let seconds):
            return seconds * 1_000_000
        case .milliseconds(let milliseconds):
            return milliseconds * 1_000
        case .microseconds(let microseconds):
            return microseconds
        case .nanoseconds(let nanoseconds):
            return nanoseconds / 1_000
        case .never:
            return Int.max
        }
    }
}

class MockBehaviorController: BehaviorController {
    var channelControllers: [String : BehaviorChannel] = [:]
    var configuration: BehaviorControllerConfig = LightControllerConfig(gamma: 1.8)
    var didInvalidate: Bool = false
    
    init(channelCount: Int) {
        for index in 0..<channelCount {
            let token = "CH\(index)"
            self.channelControllers[token] = MockBehaviorChannel()
        }
    }
    
    func invalidateRefreshTimer() {
        self.didInvalidate = true
    }
}

class MockBehaviorChannel: BehaviorChannel {
    var channelGamma: Double = 1.8
    var rootController: BehaviorController?
    var lastUpdate: Date = Date.distantPast
    var brightnessDelta: Double = 1.0
    var interval: TimeInterval = 30.0

    func set(layer: ChannelLayer, forType type: ChannelLayerType) {
        // Not Needed for Tests
    }

    func segment(forDate date: Date) -> ChannelSegment {
        let startDate = date.addingTimeInterval(-self.interval)
        let endDate = date.addingTimeInterval(self.interval)
        return MockChannelSegment(startBrightness: 0.0, endBrightness: brightnessDelta, startDate: startDate, endDate: endDate)
    }

    func update(forDate date: Date) {
        self.lastUpdate = date
    }
}

class BehaviorTests: XCTestCase {
    func testDefaultRefresh() {
        let testBehavior = DefaultLightBehavior()

        let mockController = MockBehaviorController(channelCount: 4)
        
        let refreshDate = Date()
        testBehavior.refresh(controller: mockController, forDate: refreshDate)
        
        var testedMocks = 0
        for case let mockChannel as MockBehaviorChannel in mockController.channelControllers.values {
            XCTAssertEqual(mockChannel.lastUpdate, refreshDate)
            testedMocks += 1
        }
        XCTAssertEqual(testedMocks, 4)
    }
    
    func testDefaultNextUpdate() {
        let testBehavior = DefaultLightBehavior()
    
        let mockController = MockBehaviorController(channelCount: 4)
        
        let refreshDate = Date()
        let result = testBehavior.nextUpdate(forController: mockController, forDate: refreshDate)
        
        let expectedRefreshRate = (1.0 * 4096.0) / 60.0 // 1.0 brightness change over 1 minute
        let expectedInterval = DispatchTimeInterval.microseconds(Int(1_000_000.0 / expectedRefreshRate))
        
        switch result {
        case .stop:
            XCTFail()
        case .oneShot(_):
            XCTFail()
        case .repeating(let date, let interval):
            XCTAssertEqual(date, refreshDate.addingTimeInterval(-30))
            XCTAssertEqual(interval.asMicroseconds(), expectedInterval.asMicroseconds())
        }
    }
    
    func testDefaultNextUpdateSleep() {
        let testBehavior = DefaultLightBehavior()
        
        let mockController = MockBehaviorController(channelCount: 4)

        let testData = [
            // Change, Should Sleep
            (0.00000, true), // Min brightness delta
            (0.00001, true), // Min brightness delta
            (0.00010, false),
            (0.00100, false),
            (0.01000, false),
            (0.33332, false),
            (0.50000, false),
            (0.75000, false),
            (1.00000, false)
        ]
        
        for (brightnessDelta, expectSleep) in testData {
            for case let channel as MockBehaviorChannel in mockController.channelControllers.values {
                channel.brightnessDelta = brightnessDelta
            }
            let refreshDate = Date()
            let result = testBehavior.nextUpdate(forController: mockController, forDate: refreshDate)
            
            switch result {
            case .stop:
                XCTFail()
            case .oneShot(let date):
                if expectSleep {
                    // Works because the mocks always add 30 seconds to the refreshDate to get the end of the segment.
                    XCTAssertEqual(date, refreshDate.addingTimeInterval(30))
                } else {
                    XCTFail("\(brightnessDelta) shouldn't sleep")
                }
            case .repeating(_, let interval):
                // Interval cannot be more than the duration (60 seconds)
                XCTAssertLessThanOrEqual(interval.asMicroseconds(), DispatchTimeInterval.seconds(60).asMicroseconds(), "\(brightnessDelta) created too long an interval")
                // There shouldn't be any events firing after the end of the segment, but it isn't possible to be perfect
                // if the interval is an integer. The live code has migrated to using microseconds to minimize this error, but
                // in practice, the maximum possible error is about 4096 units of time that nextUpdate() is returning.
                // Previously that was milliseconds (4s) but now it is microseconds (4ms), which should be fine in practice.
                // Being off by 4 milliseconds isn't really going to be noticeable by users.
                XCTAssertLessThanOrEqual(DispatchTimeInterval.seconds(60).asMicroseconds() % (interval.asMicroseconds()), 2048, "\(brightnessDelta) should stay under the allowable 30 ms drift")
                if expectSleep {
                    XCTFail("\(brightnessDelta) should sleep")
                }
            }
        }
    }

    func testDefaultNextUpdateLargeInterval() {
        let testBehavior = DefaultLightBehavior()
        let mockController = MockBehaviorController(channelCount: 1)

        for case let channel as MockBehaviorChannel in mockController.channelControllers.values {
            channel.brightnessDelta = 1.0 / 4096
            channel.interval = 60 * 30.0
        }

        let refreshDate = Date()
        let result = testBehavior.nextUpdate(forController: mockController, forDate: refreshDate)

        switch result {
        case .repeating( _, let dispatchInterval):
            switch dispatchInterval {
            case .milliseconds(let milliseconds):
                // Good
                XCTAssertGreaterThan(milliseconds, 1000 * 1000)
            default:
                XCTFail("Long intervals shouldn't provide anything but milliseconds")
            }
        default:
            XCTFail("Should get a repeating interval")
        }
    }
    
    func testPreviewRefresh() {
        let startDate = Date()
        let testBehavior = PreviewLightBehavior(startDate: startDate)
        
        let mockController = MockBehaviorController(channelCount: 4)
        
        let testData: [(TimeInterval, Bool)] = [
            // Interval from Start, Should Have Signaled
            (0.0, false),
            (5.0, false),
            (15.0, false),
            (30.0, false),
            (59.0, false),
            (59.9, false),
            (60.0, true),
            (120.0, true)
        ]
        
        for (interval, shouldInvalidate) in testData {
            mockController.didInvalidate = false
            
            let refreshDate = startDate.addingTimeInterval(interval)
            testBehavior.refresh(controller: mockController, forDate: refreshDate)

            XCTAssertEqual(mockController.didInvalidate, shouldInvalidate, "Interval: \(interval)")
            
            var testedMocks = 0
            for case let mockChannel as MockBehaviorChannel in mockController.channelControllers.values {
                XCTAssertNotEqual(mockChannel.lastUpdate, refreshDate)
                testedMocks += 1
            }
            XCTAssertEqual(testedMocks, 4)
        }
    }
    
    func testPreviewNextUpdate() {
        let startDate = Date()
        let testBehavior = PreviewLightBehavior(startDate: startDate)
        
        let mockController = MockBehaviorController(channelCount: 4)
        
        let testData: [(TimeInterval, Bool)] = [
            // Interval from Start, Should Be Running
            (0.0, true),
            (5.0, true),
            (15.0, true),
            (30.0, true),
            (59.0, true),
            (59.9, true),
            (60.0, false),
            (120.0, false)
        ]
        
        for (interval, shouldBeRunning) in testData {
            let refreshDate = startDate.addingTimeInterval(interval)
            let result = testBehavior.nextUpdate(forController: mockController, forDate: refreshDate)

            switch result {
            case .stop:
                XCTAssertEqual(shouldBeRunning, false)
            case .oneShot(_):
                XCTFail()
            case .repeating(let date, let interval):
                XCTAssertEqual(shouldBeRunning, true)
                XCTAssertEqual(date, refreshDate)
                XCTAssertEqual(interval.asMicroseconds(), DispatchTimeInterval.milliseconds(10).asMicroseconds())
            }
        }
    }
    
    static var allTests = [
        ("testDefaultRefresh", testDefaultRefresh),
        ("testDefaultNextUpdate", testDefaultNextUpdate),
        ("testDefaultNextUpdateSleep", testDefaultNextUpdateSleep),
        ("testDefaultNextUpdateLargeInterval", testDefaultNextUpdateLargeInterval),
        ("testPreviewRefresh", testPreviewRefresh),
        ("testPreviewNextUpdate", testPreviewNextUpdate)
    ]
}


