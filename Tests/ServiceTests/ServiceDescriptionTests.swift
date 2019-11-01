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

import Yams
@testable import Service



class ServiceDescriptionTests: XCTestCase {
    func testEmptyControllerConfiguration() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceControllerDescription.self, from: jsonData)
            XCTFail("Empty configuration should throw, because of missing properties")
        } catch {
            // Pass
        }
    }

    func testSimulatorControllerConfiguration() {
        let jsonData: JsonDictionary = [
            "type": "simulated",
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let controller = try decoder.decode(ServiceControllerDescription.self, from: jsonData)
            XCTAssertEqual(controller.type, .simulated)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertNil(controller.address)
            XCTAssertNil(controller.frequency)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testPca9685ControllerConfiguration_Complete() {
        let jsonData: JsonDictionary = [
            "type": "pca9685",
            "frequency": 960,
            "address": 0x68,
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let controller = try decoder.decode(ServiceControllerDescription.self, from: jsonData)
            XCTAssertEqual(controller.type, .pca9685)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertEqual(controller.frequency, 960)
            XCTAssertEqual(controller.address, 0x68)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testRaspberryPwmControllerConfiguration_Minimum() {
        let jsonData: JsonDictionary = [
            "type": "raspberryPwm",
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let controller = try decoder.decode(ServiceControllerDescription.self, from: jsonData)
            XCTAssertEqual(controller.type, .raspberryPwm)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertNil(controller.address)
            XCTAssertNil(controller.frequency)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testRaspberryPwmControllerConfiguration_Complete() {
        let jsonData: JsonDictionary = [
            "type": "raspberryPwm",
            "frequency": 960,
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let controller = try decoder.decode(ServiceControllerDescription.self, from: jsonData)
            XCTAssertEqual(controller.type, .raspberryPwm)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertEqual(controller.frequency, 960)
            XCTAssertNil(controller.address)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testMcp4725ControllerConfiguration_Complete() {
        let jsonData: JsonDictionary = [
            "type": "mcp4725",
            "address": 0x68,
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let controller = try decoder.decode(ServiceControllerDescription.self, from: jsonData)
            XCTAssertEqual(controller.type, .mcp4725)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertNil(controller.frequency)
            XCTAssertEqual(controller.address, 0x68)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testHardwareConfiguration_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceDescription.self, from: jsonData)
            XCTFail("Empty configuration should throw, because of missing properties")
        } catch {
            // Pass
        }
    }

    func testHardwareConfiguration_Incomplete() {
        let jsonData: JsonDictionary = [
            "user": "test_user",
            "board": "raspberryPi",
            "controllers": [:]
        ]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceDescription.self, from: jsonData)
            XCTFail("Incomplete configuration (missing controllers) should throw an exception")
        } catch {
            // Pass
        }
    }

    func testHardwareConfiguration_Complete() {
        let jsonData: JsonDictionary = [
            "user": "test_user",
            "board": "raspberryPi",
            "log-level": "debug",
            "controllers": [[
                "type": "mcp4725",
                "address": 0x68,
                "channels": [
                    "primary": 0,
                    "secondary": 1
                ]
            ]]
        ]
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(ServiceDescription.self, from: jsonData)
            XCTAssertEqual(config.username, "test_user")
            XCTAssertEqual(config.board, .raspberryPi)
            XCTAssertEqual(config.controllers.count, 1)
            XCTAssertEqual(config.controllers[0].type, .mcp4725)
            XCTAssertEqual(config.logLevel, .debug)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testHardwareConfiguration_RaspberryPiExample_Json() {
        let jsonString = """
        {
            "user": "pi",
            "board": "raspberryPi",

            "controllers": [
                {
                    "type": "raspberryPwm",
                    "frequency": 1440,
                    "gamma": 2.2,
                    "channels": {
                        "primary": 0,
                        "secondary": 1
                    }
                }
            ]
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        do {
            let decoder = JSONDecoder()
            let config = try decoder.decode(ServiceDescription.self, from: jsonData)
            XCTAssertEqual(config.username, "pi")
            XCTAssertEqual(config.board, .raspberryPi)
            XCTAssertEqual(config.controllers.count, 1)
            XCTAssertEqual(config.controllers[0].type, .raspberryPwm)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testHardwareConfiguration_RaspberryPiExample_Yaml() {
        let yamlString = """
        user: pi
        board: raspberryPi

        controllers:
            - type: raspberryPwm
              frequency: 1440
              gamma: 2.2
              channels:
                primary: 0
                secondary: 1
        """
        
        do {
            let decoder = YAMLDecoder()
            let config = try decoder.decode(ServiceDescription.self, from: yamlString)
            XCTAssertEqual(config.username, "pi")
            XCTAssertEqual(config.board, .raspberryPi)
            XCTAssertEqual(config.controllers.count, 1)
            XCTAssertEqual(config.controllers[0].type, .raspberryPwm)
        } catch {
            XCTFail("\(error)")
        }
    }

    static var allTests = [
        ("testEmptyControllerConfiguration", testEmptyControllerConfiguration),
        ("testSimulatorControllerConfiguration", testSimulatorControllerConfiguration),
        ("testPca9685ControllerConfiguration_Complete", testPca9685ControllerConfiguration_Complete),
        ("testRaspberryPwmControllerConfiguration_Minimum", testRaspberryPwmControllerConfiguration_Minimum),
        ("testRaspberryPwmControllerConfiguration_Complete", testRaspberryPwmControllerConfiguration_Complete),
        ("testMcp4725ControllerConfiguration_Complete", testMcp4725ControllerConfiguration_Complete),
        ("testHardwareConfiguration_Empty", testHardwareConfiguration_Empty),
        ("testHardwareConfiguration_Incomplete", testHardwareConfiguration_Incomplete),
        ("testHardwareConfiguration_Complete", testHardwareConfiguration_Complete),
        ("testHardwareConfiguration_RaspberryPiExample_Json", testHardwareConfiguration_RaspberryPiExample_Json),
        ("testHardwareConfiguration_RaspberryPiExample_Yaml", testHardwareConfiguration_RaspberryPiExample_Yaml),
    ]
}
