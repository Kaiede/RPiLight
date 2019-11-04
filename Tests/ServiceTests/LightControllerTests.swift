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

import LED
import Logging
@testable import Service

class MockBehavior: Behavior {
    var refreshCount: Int = 0
    var stopsAt: Int = 1
    var shouldStop: Bool = false
    var didStop: Bool = false
    var intervalMs: Int = 10

    init() {}

    func refresh(controller: BehaviorController, forDate date: Date) {
        self.refreshCount += 1
        if self.refreshCount > self.stopsAt {
            self.shouldStop = true
        }
        controller.invalidateRefreshTimer()
    }

    func segment(forController controller: BehaviorController, date: Date) -> LightBehaviorSegment {
        // Disable watchdog for these behaviors.
        let mockSegment = MockChannelSegment(startBrightness: 0.0, endBrightness: 1.0, startDate: Date.distantPast, endDate: Date.distantFuture)
        return LightBehaviorSegment(segment: mockSegment, update: self.nextUpdate(forController: controller, forDate: date))
    }

    func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        if self.shouldStop {
            self.didStop = true
            return .stop
        } else {
            return .repeating(date, .milliseconds(self.intervalMs))
        }
    }
}

struct MockChannelPoint: ChannelPoint {
    var time: DateComponents
    var setting: ChannelSetting

    init(time: DateComponents, setting: ChannelSetting) {
        self.time = time
        self.setting = setting
    }
}

class MockOneShotBehavior: Behavior {
    var refreshCount: Int = 0
    var updateCount: Int = 0
    var stopAfter: Int = 2
    var didStop: Bool = false

    init() {}

    func refresh(controller: BehaviorController, forDate date: Date) {
        self.refreshCount += 1
    }

    func segment(forController controller: BehaviorController, date: Date) -> LightBehaviorSegment {
        // Disable watchdog for these behaviors.
        let mockSegment = MockChannelSegment(startBrightness: 0.0, endBrightness: 1.0, startDate: Date.distantPast, endDate: Date.distantFuture)
        return LightBehaviorSegment(segment: mockSegment, update: self.nextUpdate(forController: controller, forDate: date))
    }

    func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        self.updateCount += 1

        if self.updateCount >= self.stopAfter {
            self.didStop = true
            return .stop
        }

        return .oneShot(date.addingTimeInterval(0.01))
    }
}

class LightControllerTests: XCTestCase {
    override class func setUp() {
        Log.pushLevel(.warn)
    }

    override class func tearDown() {
        Log.popLevel()
    }

    func testChannelEvent() {        
        // This ensures we know that we are actually getting brightness, not intensity.
        let mockConfiguration = LightControllerConfig(gamma: 2.0)

        let eventDate = LightControllerTests.dateFormatter.date(from: "08:00:00")!
        let eventComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: eventDate)
        let eventConfig = MockChannelPoint(time: eventComponents, setting: .intensity(0.5))

        let testEvent = ChannelPointWrapper(configuration: mockConfiguration, event: eventConfig)

        XCTAssertEqual(testEvent.time, eventComponents)
        XCTAssertEqual(testEvent.brightness, pow(0.5, (1/mockConfiguration.gamma)))
    }

    func testChannelBinding() {
        let mockController = MockBehaviorController(channelCount: 4)
        let channelControllers = mockController.channelControllers

        for controller in channelControllers.values {
            XCTAssertNil(controller.rootController)
        }

        let testController = LightController(configuration: LightControllerConfig(gamma: 1.8), channelControllers: channelControllers, behavior: MockBehavior())

        for controller in testController.channelControllers.values {
            XCTAssertNotNil(controller.rootController)
        }
    }

    func testAutoStop() {
        let mockController = MockBehaviorController(channelCount: 4)
        let testController = LightController(configuration: LightControllerConfig(gamma: 1.8), channelControllers: mockController.channelControllers, behavior: MockBehavior())

        let controllerStopped = expectation(description: "Controller Stops")
        testController.setStopHandler { (_) in
            controllerStopped.fulfill()
        }
        testController.start()

        waitForExpectations(timeout: 0.25)
    }

    func testForceStop() {
        let mockController = MockBehaviorController(channelCount: 4)
        let mockBehavior = MockBehavior()
        mockBehavior.intervalMs = 1000
        let testController = LightController(configuration: LightControllerConfig(gamma: 1.8), channelControllers: mockController.channelControllers, behavior: mockBehavior)

        let controllerStopped = expectation(description: "Controller Stops")
        testController.setStopHandler { (_) in
            controllerStopped.fulfill()
        }
        testController.start()
        testController.stop()

        waitForExpectations(timeout: 0.25) { (error) in
            // Shouldn't have waited until a refresh to stop the controller
            XCTAssertFalse(mockBehavior.didStop)
        }
    }

    func testOneShot() {
        let mockController = MockBehaviorController(channelCount: 4)
        let mockBehavior = MockOneShotBehavior()
        let testController = LightController(configuration: LightControllerConfig(gamma: 1.8), channelControllers: mockController.channelControllers, behavior: mockBehavior)

        let controllerStopped = expectation(description: "Controller Stops")
        testController.setStopHandler { (_) in
            controllerStopped.fulfill()
        }
        testController.start()

        waitForExpectations(timeout: 0.25) { (error) in
            XCTAssertEqual(mockBehavior.refreshCount, mockBehavior.stopAfter)
            XCTAssertEqual(mockBehavior.updateCount, mockBehavior.stopAfter)
            XCTAssertTrue(mockBehavior.didStop)
        }
    }

    static var allTests = [
        ("testChannelEvent", testChannelEvent),
        ("testChannelBinding", testChannelBinding),
        ("testAutoStop", testAutoStop),
        ("testForceStop", testForceStop),
        ("testOneShot", testOneShot)
    ]

    static public let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()
}

