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

class MockBehaviorController: BehaviorController {
    var channelControllers: [String : BehaviorChannel] = [:]
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
    var rootController: BehaviorController?
    var lastUpdate: Date = Date.distantPast
    var brightnessDelta: Double = 1.0
    
    func segment(forDate date: Date) -> ChannelSegment {
        let startDate = date.addingTimeInterval(-30.0)
        let endDate = date.addingTimeInterval(30.0)
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
        let expectedInterval = Int(1000 / expectedRefreshRate)
        
        switch result {
        case .stop:
            XCTFail()
        case .oneShot(_):
            XCTFail()
        case .repeating(let date, let interval):
            XCTAssertEqual(date, refreshDate.addingTimeInterval(-30))
            XCTAssertEqual(interval, expectedInterval)
        }
    }
    
    func testDefaultNextUpdateSleep() {
        let testBehavior = DefaultLightBehavior()
        
        let mockController = MockBehaviorController(channelCount: 4)

        let testData = [
            // Change, Should Sleep
            (0.00000, true),
            (0.00001, true),
            (0.00010, false),
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
                    XCTAssertEqual(date, refreshDate.addingTimeInterval(30))
                } else {
                    XCTFail()
                }
            case .repeating(_, _):
                if expectSleep {
                    XCTFail()
                }
            }
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
                XCTAssertEqual(interval, 10)
            }
        }
    }
    
    static var allTests = [
        ("testDefaultRefresh", testDefaultRefresh),
        ("testDefaultNextUpdate", testDefaultNextUpdate),
        ("testDefaultNextUpdateSleep", testDefaultNextUpdateSleep),
        ("testPreviewRefresh", testPreviewRefresh),
        ("testPreviewNextUpdate", testPreviewNextUpdate)
    ]
}


