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
@testable import Service

class ServiceConfigTests: XCTestCase {
    func testEmptyControllerConfiguration() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTFail("Empty configuration should throw, because of missing properties")
        } catch {
            // Pass
        }
    }

    /*
    public let type: ServiceControllerType
    public let gamma: Gamma
    public let channels: [String : Int]

    // Conditional Controller Settings
    public let frequency: Int?
    public let address: Int?
    */

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
            let controller = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(controller.type, .simulated)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertNil(controller.address)
            XCTAssertNil(controller.frequency)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testPca9685ControllerConfiguration_Incomplete() {
        let jsonData: JsonDictionary = [
            "type": "pca9685",
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTFail("Incomplete configuration should throw, because of missing properties")
        } catch {
            // Pass
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
            let controller = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
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
            let controller = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(controller.type, .raspberryPwm)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertNil(controller.address)
            XCTAssertNotNil(controller.frequency)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testRaspberryPwmControllerConfiguration_Complete() {
        let jsonData: JsonDictionary = [
            "type": "raspberryPwm",
            "frequency": 960,
            "address": 0x68,
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let controller = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(controller.type, .raspberryPwm)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertEqual(controller.frequency, 960)
            XCTAssertNil(controller.address)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testMcp4725ControllerConfiguration_Incomplete() {
        let jsonData: JsonDictionary = [
            "type": "mcp4725",
            "channels": [
                "primary": 0,
                "secondary": 1
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTFail("Incomplete configuration should throw, because of missing properties")
        } catch {
            // Pass
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
            let controller = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(controller.type, .mcp4725)
            XCTAssertEqual(controller.channels.count, 2)
            XCTAssertNil(controller.frequency)
            XCTAssertEqual(controller.address, 0x68)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFrequencyBounds() {
        var jsonData: JsonDictionary = [
            "type": "raspberryPwm",
            "channels": [:]
        ]
        do {
            let decoder = JSONDecoder()

            jsonData["frequency"] = -480
            var config = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 480)

            jsonData["frequency"] = 0
            config = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 480)

            jsonData["frequency"] = 120
            config = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 120)

            jsonData["frequency"] = 960
            config = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 960)

            jsonData["frequency"] = 1440
            config = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 1440)

            jsonData["frequency"] = 2500
            config = try decoder.decode(ServiceControllerConfiguration.self, from: jsonData)
            XCTAssertEqual(config.frequency, 2000)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testGammaBounds() {
        var jsonData: JsonDictionary = [
            "user": "test_user",
            "board": "raspberryPi",
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

    func testHardwareConfiguration_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ServiceConfiguration.self, from: jsonData)
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
            let _ = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTFail("Incomplete configuration (missing controllers) should throw an exception")
        } catch {
            // Pass
        }
    }

    func testHardwareConfiguration_Complete() {
        let jsonData: JsonDictionary = [
            "user": "test_user",
            "board": "raspberryPi",
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
            let config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
            XCTAssertEqual(config.username, "test_user")
            XCTAssertEqual(config.board, .raspberryPi)
            XCTAssertEqual(config.controllers.count, 1)
            XCTAssertEqual(config.controllers[0].type, .mcp4725)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testHardwareConfiguration_RaspberryPiExample() {
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
            let config = try decoder.decode(ServiceConfiguration.self, from: jsonData)
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
        ("testPca9685ControllerConfiguration_Incomplete", testPca9685ControllerConfiguration_Incomplete),
        ("testPca9685ControllerConfiguration_Complete", testPca9685ControllerConfiguration_Complete),
        ("testRaspberryPwmControllerConfiguration_Minimum", testRaspberryPwmControllerConfiguration_Minimum),
        ("testRaspberryPwmControllerConfiguration_Complete", testRaspberryPwmControllerConfiguration_Complete),
        ("testMcp4725ControllerConfiguration_Incomplete", testMcp4725ControllerConfiguration_Incomplete),
        ("testMcp4725ControllerConfiguration_Complete", testMcp4725ControllerConfiguration_Complete),
        ("testFrequencyBounds", testFrequencyBounds),
        ("testGammaBounds", testGammaBounds),
        ("testHardwareConfiguration_Empty", testHardwareConfiguration_Empty),
        ("testHardwareConfiguration_Incomplete", testHardwareConfiguration_Incomplete),
        ("testHardwareConfiguration_Complete", testHardwareConfiguration_Complete),
        ("testHardwareConfiguration_RaspberryPiExample", testHardwareConfiguration_RaspberryPiExample),
    ]
}
