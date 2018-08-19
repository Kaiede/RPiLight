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
import PWM
@testable import Core

class MockChannel: Channel {
    var token: String = ""
    var gamma: Double = 1.0
    var minIntensity: Double = 0.0

    var setting: ChannelSetting = .intensity(0.0)
}

class MockLayer: ChannelLayer {
    var activeIndex: Int = 0
    var lightLevel: Double = 0.0
    
    func rateOfChange(forDate date: Date) -> ChannelRateOfChange {
        return (rate: 1.0 / 4096.0 , segmentStart: Date.distantPast, segmentEnd: Date.distantFuture)
    }

    func lightLevel(forDate now: Date) -> Double {
        self.activeIndex += 1
        return self.lightLevel
    }
}

class ChannelControllerTests: XCTestCase {
    func testSettingBaseLayer() {
        let testChannel = MockChannel()
        let testController = ChannelController(channel: testChannel)

        let layer1 = MockLayer()
        layer1.lightLevel = 1.0
        let layer2 = MockLayer()
        layer2.lightLevel = 0.5

        testController.setBase(layer: layer1)

        XCTAssertEqual(testController.layers.count, 1)
        XCTAssertEqual(testController.layers[0].lightLevel(forDate: Date()), 1.0)

        testController.setBase(layer: layer2)

        XCTAssertEqual(testController.layers.count, 1)
        XCTAssertEqual(testController.layers[0].lightLevel(forDate: Date()), 0.5)
    }

    func testUpdateNoLayer() {
        let testChannel = MockChannel()
        let testController = ChannelController(channel: testChannel)

        testChannel.setting = .brightness(1.0)

        testController.update(forDate: Date())
        let channelSetting = testChannel.setting.asBrightness(withGamma: testChannel.gamma)
        XCTAssertEqual(channelSetting, 0.0)
    }

    func testChannelUpdate() {
        let testChannel = MockChannel()
        let testLayer = MockLayer()
        let testController = ChannelController(channel: testChannel)

        testController.setBase(layer: testLayer)

        let testData = [ 0.0, 0.25, 0.50, 0.75, 1.0 ]
        for testValue in testData {
            testLayer.lightLevel = testValue
            testController.update(forDate: Date())

            let channelSetting = testChannel.setting.asBrightness(withGamma: testChannel.gamma)
            XCTAssertEqual(channelSetting, testValue)
        }
    }
    
    func testChannelInvalidate() {
        let mockController = MockBehaviorController(channelCount: 4)
        let mockChannel = MockChannel()
        let testController = ChannelController(channel: mockChannel)

        testController.rootController = mockController
        
        // Case 1: Setting Layer
        XCTAssertFalse(mockController.didInvalidate)
        let testLayer = MockLayer()
        testController.setBase(layer: testLayer)
        XCTAssertTrue(mockController.didInvalidate)
        
        mockController.didInvalidate = false
        
        // Case 2: Changing Active Index on Layer (Mock triggers this on update)
        XCTAssertFalse(mockController.didInvalidate)
        testController.update(forDate: Date())
        XCTAssertTrue(mockController.didInvalidate)
    }
    
    func testChannelRateOfChange() {
        let testChannel = MockChannel()
        let testLayer = MockLayer()
        let testController = ChannelController(channel: testChannel)
        
        testController.setBase(layer: testLayer)
        
        let (testRate, testSegmentStart, testSegmentEnd) = testController.rateOfChange(forDate: Date())
        XCTAssertEqual(testRate, 1.0 / 4096.0)
        XCTAssertEqual(testSegmentStart, Date.distantPast)
        XCTAssertEqual(testSegmentEnd, Date.distantFuture)
    }

    static var allTests = [
        ("testSettingBaseLayer", testSettingBaseLayer),
        ("testUpdateNoLayer", testUpdateNoLayer),
        ("testChannelUpdate", testChannelUpdate),
        ("testChannelInvalidate", testChannelInvalidate),
        ("testChannelRateOfChange", testChannelRateOfChange)
    ]
}

