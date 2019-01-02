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

typealias JsonDictionary = [String: Any]

extension JSONDecoder {
    // Helper function for testing.
    // Enables using Dictionaries directly
    func decode<T>(_ type: T.Type, from dict: JsonDictionary) throws -> T where T : Decodable {
        let data: Data = try JSONSerialization.data(withJSONObject: dict)
        return try self.decode(type, from: data)
    }
}

class ServiceConfigTests: XCTestCase {
    func testEmptyHardwareConfiguration() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTFail("Empty configuration should throw, because of missing properties: user, pwmMode, board")
        } catch {
            // Pass
        }
    }
    
    func testMinimumHardwareConfiguration() {
        let jsonData: JsonDictionary = [
            "user": "test_user",
            "board": "raspberryPi",
            "pwmMode": "simulated"
        ]
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.username, "test_user")
            XCTAssertEqual(config.logLevel, .info)
            XCTAssertEqual(config.type, .simulated)
            XCTAssertEqual(config.board, .raspberryPi)
            XCTAssertEqual(config.frequency, 480)
            XCTAssertEqual(config.gamma, 1.8)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFullHardwareConfiguration() {
        let jsonData: JsonDictionary = [
            "user": "test_user",
            "logging": "warn",
            "board": "raspberryPi",
            "pwmMode": "raspberryPwm",
            "freq": 1440,
            "gamma": 2.2
        ]
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.username, "test_user")
            XCTAssertEqual(config.logLevel, .warn)
            XCTAssertEqual(config.type, .raspberryPwm)
            XCTAssertEqual(config.board, .raspberryPi)
            XCTAssertEqual(config.frequency, 1440)
            XCTAssertEqual(config.gamma, 2.2)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFrequencyBounds() {
        var jsonData: JsonDictionary = [
            "user": "test_user",
            "board": "raspberryPi",
            "pwmMode": "simulated",
        ]
        do {
            let decoder = JSONDecoder()

            jsonData["freq"] = -480
            var config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 480)

            jsonData["freq"] = 0
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 480)

            jsonData["freq"] = 120
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 120)

            jsonData["freq"] = 960
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 960)

            jsonData["freq"] = 1440
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 1440)

            jsonData["freq"] = 2500
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 2000)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testGammaBounds() {
        var jsonData: JsonDictionary = [
            "user": "test_user",
            "board": "raspberryPi",
            "pwmMode": "simulated",
        ]
        do {
            let decoder = JSONDecoder()

            jsonData["gamma"] = -1.8
            var config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.gamma, 1.8)

            jsonData["gamma"] = 0.0
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.gamma, 1.8)

            jsonData["gamma"] = 1.0
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.gamma, 1.0)

            jsonData["gamma"] = 2.2
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.gamma, 2.2)

            jsonData["gamma"] = 2.6
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.gamma, 2.6)

            jsonData["gamma"] = 3.2
            config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.gamma, 3.0)
        } catch {
            XCTFail("\(error)")
        }
    }

    static var allTests = [
        ("testEmptyHardwareConfiguration", testEmptyHardwareConfiguration),
        ("testMinimumHardwareConfiguration", testMinimumHardwareConfiguration),
        ("testFullHardwareConfiguration", testFullHardwareConfiguration),
        ("testFrequencyBounds", testFrequencyBounds),
        ("testGammaBounds", testGammaBounds)
    ]
}
