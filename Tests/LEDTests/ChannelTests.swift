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
@testable import LED

class MockModuleImpl: LEDModuleImpl {
    var channelMap: [String: Int] = [:]

    init(channel: Int = 0, intensity: Double = 0.0) {
        self.lastChannel = channel
        self.lastIntensity = intensity
    }

    var lastIntensity: Double
    var lastChannel: Int
    func applyIntensity(_ intensity: Double, toChannel channel: Int) {
        self.lastChannel = channel
        self.lastIntensity = intensity
    }
}

class ChannelTests: XCTestCase {
    func testIntensityEvent() {
        let mockImpl = MockModuleImpl()
        let testChannel = LEDChannel(impl: mockImpl, token: "Second", id: 1)

        testChannel.intensity = 1.0
        XCTAssertEqual(mockImpl.lastChannel, 1)
        XCTAssertEqual(mockImpl.lastIntensity, 1.0)
        testChannel.intensity = 0.5
        XCTAssertEqual(mockImpl.lastChannel, 1)
        XCTAssertEqual(mockImpl.lastIntensity, 0.5)
        testChannel.intensity = 0.0
        XCTAssertEqual(mockImpl.lastChannel, 1)
        XCTAssertEqual(mockImpl.lastIntensity, 0.0)
    }

    func testIntensityClamping() {
        let mockImpl = MockModuleImpl()
        let testChannel = LEDChannel(impl: mockImpl, token: "Second", id: 1)
        testChannel.minIntensity = 0.025

        testChannel.intensity = 1.0
        XCTAssertEqual(mockImpl.lastChannel, 1)
        XCTAssertEqual(mockImpl.lastIntensity, 1.0)
        testChannel.intensity = 0.026
        XCTAssertEqual(mockImpl.lastChannel, 1)
        XCTAssertEqual(mockImpl.lastIntensity, 0.026)
        testChannel.intensity = 0.024
        XCTAssertEqual(mockImpl.lastChannel, 1)
        XCTAssertEqual(mockImpl.lastIntensity, 0.0)
    }

    static var allTests = [
        ("testIntensityEvent", testIntensityEvent),
        ("testIntensityClamping", testIntensityClamping)
    ]
}