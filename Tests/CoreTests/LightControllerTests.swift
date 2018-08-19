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
@testable import Core

class MockBehavior: Behavior {
    var shouldStop: Bool = false
    
    init() {}
    
    func refresh(controller: BehaviorController, forDate date: Date) {
        self.shouldStop = true
        controller.invalidateRefreshTimer()
    }
    
    func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        if self.shouldStop {
            return .stop
        } else {
            return .repeating(date, 10)
        }
    }
}

class MockOneShotBehavior: Behavior {
    var refreshCount: Int = 0
    var updateCount: Int = 0
    var stopAfter: Int = 2
    
    init() {}
    
    func refresh(controller: BehaviorController, forDate date: Date) {
        self.refreshCount += 1
    }
    
    func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        self.updateCount += 1
        
        if self.updateCount > self.stopAfter {
            return .stop
        }
        
        return .oneShot(date.addingTimeInterval(0.01))
    }
}

class LightControllerTests: XCTestCase {
    func testChannelEvent() {
        let mockChannel = MockChannel()
        
        // This ensures we know that we are actually getting brightness, not intensity.
        mockChannel.gamma = 2.0

        let eventDate = LightControllerTests.dateFormatter.date(from: "08:00:00")!
        let eventComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: eventDate)
        let eventConfig = ChannelEventConfig(time: eventComponents, setting: .intensity(0.5))
        
        let testEvent = ChannelEvent(channel: mockChannel, event: eventConfig)
        
        XCTAssertEqual(testEvent.time, eventComponents)
        XCTAssertEqual(testEvent.brightness, pow(0.5, (1/mockChannel.gamma)))
    }
    
    func testAutoStop() {
        let mockController = MockBehaviorController(channelCount: 4)
        let testController = LightController(channelControllers: mockController.channelControllers, behavior: MockBehavior())
        
        let expectation = XCTestExpectation(description: "Controller Stops")
        testController.setStopHandler { (_) in
            expectation.fulfill()
        }
        testController.start()
        
        wait(for: [expectation], timeout: 0.25)
    }
    
    func testForceStop() {
        let mockController = MockBehaviorController(channelCount: 4)
        let mockBehavior = MockBehavior()
        let testController = LightController(channelControllers: mockController.channelControllers, behavior: mockBehavior)
        
        let expectation = XCTestExpectation(description: "Controller Stops")
        testController.setStopHandler { (_) in
            expectation.fulfill()
        }
        testController.start()
        testController.stop()
        
        wait(for: [expectation], timeout: 0.25)
        
        // Shouldn't have waited until a refresh to stop the controller
        XCTAssertFalse(mockBehavior.shouldStop)
    }
    
    func testOneShot() {
        let mockController = MockBehaviorController(channelCount: 4)
        let mockBehavior = MockOneShotBehavior()
        let testController = LightController(channelControllers: mockController.channelControllers, behavior: mockBehavior)
        
        let expectation = XCTestExpectation(description: "Controller Stops")
        testController.setStopHandler { (_) in
            expectation.fulfill()
        }
        testController.start()
        
        wait(for: [expectation], timeout: 0.25)
        
        XCTAssertEqual(mockBehavior.refreshCount, mockBehavior.stopAfter)
        XCTAssertEqual(mockBehavior.updateCount, mockBehavior.stopAfter + 1)
    }
    
    static var allTests = [
        ("testChannelEvent", testChannelEvent),
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



