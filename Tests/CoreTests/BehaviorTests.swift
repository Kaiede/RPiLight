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
        
        switch result {
        case .stop:
            XCTFail()
        case .oneShot(_):
            XCTFail()
        case .repeating(let date, let interval):
            XCTAssertEqual(date, refreshDate)
            XCTAssertEqual(interval, 1000 / 24)
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
        ("testPreviewRefresh", testPreviewRefresh),
        ("testPreviewNextUpdate", testPreviewNextUpdate)
    ]
}


