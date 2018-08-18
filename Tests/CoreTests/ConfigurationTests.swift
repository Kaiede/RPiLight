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

/*
 "hardware" :{
 "board": "PiZero",
 "pwmMode": "simulated",
 "channels": 1
 },
 */



class ConfigurationTests: XCTestCase {
    func testEmptyHardwareConfig() {
        let jsonData: JsonDict = [:]

        do {
            let _ = try Hardware(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testMinHardwareConfig() {
        let jsonData: JsonDict = [
            "pwmMode": "simulated",
        ]

        do {
            let testHardware = try Hardware(json: jsonData)

            // Required
            XCTAssertEqual(testHardware.type, .simulated)

            // Optional
            XCTAssertEqual(testHardware.channelCount, 1)
            XCTAssertEqual(testHardware.board, BoardType.bestGuess())
            XCTAssertEqual(testHardware.frequency, 480)
            XCTAssertEqual(testHardware.gamma, 1.8)
        } catch {
            XCTFail()
        }
    }

    func testHardwareConfig() {
        let jsonData: JsonDict = [
            "board": "PiZero",
            "pwmMode": "simulated",
            "channels": 2,
            "freq": 960,
            "gamma": 2.2
        ]

        do {
            let testHardware = try Hardware(json: jsonData)
            XCTAssertEqual(testHardware.board, .raspberryPiV6)
            XCTAssertEqual(testHardware.type, .simulated)
            XCTAssertEqual(testHardware.channelCount, 2)
            XCTAssertEqual(testHardware.frequency, 960)
            XCTAssertEqual(testHardware.gamma, 2.2)
        } catch {
            XCTFail()
        }
    }

    func testEmptyChannelConfig() {
        let jsonData: JsonDict = [:]

        do {
            let _ = try ChannelInfo(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testChannelConfig() {
        let jsonData: JsonDict = [
            "token": "PWM00",
            "minIntensity": 0.25
        ]

        do {
            let testChannel = try ChannelInfo(json: jsonData)
            XCTAssertEqual(testChannel.token, "PWM00")
            XCTAssertEqual(testChannel.minIntensity, 0.25)
        } catch {
            XCTFail()
        }
    }

    static var allTests = [
        ("testEmptyHardwareConfig", testEmptyHardwareConfig),
        ("testMinHardwareConfig", testMinHardwareConfig),
        ("testHardwareConfig", testHardwareConfig),
        ("testEmptyChannelConfig", testEmptyChannelConfig),
        ("testChannelConfig", testChannelConfig)
    ]
}
