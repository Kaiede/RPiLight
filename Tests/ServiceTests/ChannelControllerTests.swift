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
@testable import Service

class MockChannel: Channel {
    var token: String = ""
    var minIntensity: Intensity = Intensity(0.0)

    var intensity: Intensity = Intensity(0.0)
}

class MockChannelSegment: ChannelSegment {
    var startBrightness: Brightness
    var endBrightness: Brightness
    var startDate: Date
    var endDate: Date

    init(startBrightness: Brightness, endBrightness: Brightness, startDate: Date, endDate: Date) {
        self.startBrightness = startBrightness
        self.endBrightness = endBrightness
        self.startDate = startDate
        self.endDate = endDate
    }
}

class MockLayer: ChannelLayer {
    var activeIndex: Int = 0
    var lightLevel: Brightness = Brightness(0.0)

    func segment(forDate date: Date) -> ChannelSegment {
        let startDate = date.addingTimeInterval(-30.0)
        let endDate = date.addingTimeInterval(30.0)
        return MockChannelSegment(startBrightness: 0.0, endBrightness: 1.0, startDate: startDate, endDate: endDate)
    }

    func lightLevel(forDate now: Date) -> Brightness {
        self.activeIndex += 1
        return self.lightLevel
    }
}

class ChannelControllerTests: XCTestCase {
    func testSettingBaseLayer() {
        let testChannel = MockChannel()
        let testController = ChannelController(channel: testChannel)

        let layer1 = MockLayer()
        layer1.lightLevel = Brightness(1.0)
        let layer2 = MockLayer()
        layer2.lightLevel = Brightness(0.5)

        testController.set(layer: layer1)

        XCTAssertEqual(testController.activeLayers.count, 1)
        XCTAssertEqual(testController.layers[0]?.lightLevel(forDate: Date()).rawValue, 1.0)

        testController.set(layer: layer2)

        XCTAssertEqual(testController.activeLayers.count, 1)
        XCTAssertEqual(testController.layers[0]?.lightLevel(forDate: Date()).rawValue, 0.5)
    }

    func testUpdateNoLayer() {
        let testChannel = MockChannel()
        let testController = ChannelController(channel: testChannel)

        testChannel.intensity = Intensity(1.0)

        testController.update(forDate: Date())
        XCTAssertEqual(testChannel.intensity.rawValue, 0.0)
    }

    func testChannelUpdate() {
        let mockBehaviorController = MockBehaviorController(channelCount: 4)
        mockBehaviorController.configuration = LightControllerConfig(gamma: 1.0)
        let testChannel = MockChannel()
        let testLayer = MockLayer()
        let testController = ChannelController(channel: testChannel)
        testController.rootController = mockBehaviorController

        testController.set(layer: testLayer)

        let testData = [ 0.0, 0.25, 0.50, 0.75, 1.0 ]
        for testValue in testData {
            let expectedValue = Intensity(rawValue: testValue)
            testLayer.lightLevel = Brightness(rawValue: testValue)
            testController.update(forDate: Date())

            XCTAssertEqual(testChannel.intensity, expectedValue)
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
        testController.set(layer: testLayer)
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

        testController.set(layer: testLayer)

        let testSegment = testController.segment(forDate: Date())
        XCTAssertEqual(testSegment.totalBrightnessChange, 1.0)
        XCTAssertEqual(testSegment.duration, 60.0)
    }

    func testSegmentUnionByLayer() {
        let now = Date()
        let nowPlus5 = now.addingTimeInterval(60.0 * 5)
        let nowPlus45 = now.addingTimeInterval(60.0 * 45)
        let nowPlus60 = now.addingTimeInterval(60.0 * 60)
        let fullBrightness = Brightness(1.0)
        let halfBrightness = Brightness(0.5)
        let testSegment1 = ChannelControllerSegment(startBrightness: fullBrightness, endBrightness: halfBrightness, startDate: now, endDate: nowPlus45)
        let testSegment2 = ChannelControllerSegment(startBrightness: halfBrightness, endBrightness: halfBrightness, startDate: nowPlus5, endDate: nowPlus60)

        var targetSegment = testSegment1
        targetSegment.unionByLayer(withSegment: testSegment2)

        // Case 1: Union of two segments should result in what the actual final brightness would be assigned to the PWM Channel at Start & Finish
        // This is an interpolation of the brightness in one segment, multiplied by the start brightness in the other.
        XCTAssertEqual(targetSegment.startBrightness.rawValue, 0.4722222222, accuracy: 0.0000000001) // startBrightness + delta(5 into segment)... then multiplied by other segment's start brightness
        XCTAssertEqual(targetSegment.endBrightness.rawValue, 0.25)

        // Case 2: Segment should represent the smallest slice of time.
        XCTAssertEqual(targetSegment.startDate, nowPlus5)
        XCTAssertEqual(targetSegment.endDate, nowPlus45)
    }

    func testSegmentUnionByChannel() {
        let now = Date()
        let nowPlus5 = now.addingTimeInterval(60.0 * 5)
        let nowPlus45 = now.addingTimeInterval(60.0 * 45)
        let nowPlus60 = now.addingTimeInterval(60.0 * 60)
        let fullBrightness = Brightness(1.0)
        let halfBrightness = Brightness(0.5)
        let testSegment1 = ChannelControllerSegment(startBrightness: fullBrightness, endBrightness: halfBrightness, startDate: now, endDate: nowPlus45)
        let testSegment2 = ChannelControllerSegment(startBrightness: halfBrightness, endBrightness: halfBrightness, startDate: nowPlus5, endDate: nowPlus60)

        var targetSegment = testSegment1
        targetSegment.unionByChannel(withSegment: testSegment2)

        // Case 1: Union of two segments should result in what the actual final brightness would be assigned to the PWM Channel at Start & Finish
        // This is an interpolation of the brightness in one segment, multiplied by the start brightness in the other.
        XCTAssertEqual(targetSegment.startBrightness.rawValue, 0.9444444444, accuracy: 0.0000000001) // startBrightness + delta(5 into segment)... then multiplied by other segment's start brightness
        XCTAssertEqual(targetSegment.endBrightness.rawValue, 0.5)

        // Case 2: Segment should represent the smallest slice of time.
        XCTAssertEqual(targetSegment.startDate, nowPlus5)
        XCTAssertEqual(targetSegment.endDate, nowPlus45)
    }

    static var allTests = [
        ("testSettingBaseLayer", testSettingBaseLayer),
        ("testUpdateNoLayer", testUpdateNoLayer),
        ("testChannelUpdate", testChannelUpdate),
        ("testChannelInvalidate", testChannelInvalidate),
        ("testChannelRateOfChange", testChannelRateOfChange),
        ("testSegmentUnionByLayer", testSegmentUnionByLayer),
        ("testSegmentUnionByChannel", testSegmentUnionByChannel)
    ]
}

