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

struct MockLayerPoint: LayerPoint {
    var time: DateComponents
    var brightness: Double

    init(time: String, brightness: Double) {
        let date = MockLayerPoint.dateFormatter.date(from: time)!
        self.time = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        self.brightness = brightness
    }

    static public let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()
}

class LayerTests: XCTestCase {
    func testActiveIndex() {
        // Segments are considered such that they don't include their start, but do include their end.
        // It's not intuitive, hence these tests.
        let testExpectations = [
            // Time, Active Index
            ("07:30:00", LayerTests.testData.count - 1),
            ("08:00:01", 0),
            ("14:00:00", 2)
        ]

        for (timeString, expectedIndex) in testExpectations {
            let testTime = MockLayerPoint.dateFormatter.date(from: timeString)!
            let testLayer = Layer(points: LayerTests.testData, startTime: testTime)

            XCTAssertEqual(testLayer.activeIndex, expectedIndex)
        } 
    }

    func testActiveSegment() {
        // Segments are considered such that they don't include their start, but do include their end.
        // It's not intuitive, hence these tests.
        let testExpectations = [
            // Time, Active Index
            ("07:30:00", LayerTests.testData.count - 1),
            ("08:00:01", 0),
            ("14:00:00", 2)
        ]

        for (timeString, expectedIndex) in testExpectations {
            let nextExpectedIndex = (expectedIndex + 1) % LayerTests.testData.count
            let testTime = MockLayerPoint.dateFormatter.date(from: timeString)!
            let testLayer = Layer(points: LayerTests.testData, startTime: testTime)
            let activeSegment = testLayer.activeSegment

            XCTAssertLessThanOrEqual(activeSegment.startDate, testTime)
            XCTAssertGreaterThanOrEqual(activeSegment.endDate, testTime)
            XCTAssertEqual(activeSegment.range.origin, LayerTests.testData[expectedIndex].brightness)
            XCTAssertEqual(activeSegment.range.end, LayerTests.testData[nextExpectedIndex].brightness)
        }
    }

    func testLightLevel() {
        let testExpectations = [
            ("08:00:00", 0.0),
            ("08:15:00", 0.125), // Midway
            ("08:30:00", 0.25),
            ("11:00:00", 0.25), // Midway
            ("12:00:00", 0.25),
            ("14:00:00", 0.50),
            ("18:00:00", 0.50),
            ("19:00:00", 0.30), // Midway
            ("20:00:00", 0.10),
            ("22:30:00", 0.10),
            ("23:00:00", 0.0)
        ]

        for (timeString, expectedBrightness) in testExpectations {
            // Start from known point every time
            let startTimeString = MockLayerPoint.dateFormatter.date(from: "00:00:00")!
            var testLayer = Layer(points: LayerTests.testData, startTime: startTimeString)

            let testDate = MockLayerPoint.dateFormatter.date(from: timeString)!
            let brightness = testLayer.lightLevel(forDate: testDate)
            XCTAssertEqual(brightness, expectedBrightness, "\(timeString)")
        }
    }

    static var testData: [MockLayerPoint] = [
        MockLayerPoint(time: "08:00:00", brightness: 0.0),
        MockLayerPoint(time: "08:30:00", brightness: 0.25),
        MockLayerPoint(time: "12:00:00", brightness: 0.25),
        MockLayerPoint(time: "14:00:00", brightness: 0.50),
        MockLayerPoint(time: "18:00:00", brightness: 0.50),
        MockLayerPoint(time: "20:00:00", brightness: 0.10),
        MockLayerPoint(time: "22:30:00", brightness: 0.10),
        MockLayerPoint(time: "23:00:00", brightness: 0.0)
    ]

    static var allTests = [
        ("testActiveIndex", testActiveIndex),
        ("testActiveSegment", testActiveSegment),
        ("testLightLevel", testLightLevel)
    ]
}
