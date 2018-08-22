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
            let _ = try HardwareConfig(json: jsonData)
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
            let testHardware = try HardwareConfig(json: jsonData)

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
            let testHardware = try HardwareConfig(json: jsonData)
            XCTAssertEqual(testHardware.board, .raspberryPiV6)
            XCTAssertEqual(testHardware.type, .simulated)
            XCTAssertEqual(testHardware.channelCount, 2)
            XCTAssertEqual(testHardware.frequency, 960)
            XCTAssertEqual(testHardware.gamma, 2.2)
        } catch {
            XCTFail()
        }
    }

    func testEmptyLunarConfig() {
        let jsonData: JsonDict = [:]

        do {
            let _ = try LunarConfig(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testMinLunarConfig() {
        let jsonData: JsonDict = [
            "start": "21:00:00",
            "end": "07:00:00"
        ]

        do {
            let testConfig = try LunarConfig(json: jsonData)

            XCTAssertEqual(testConfig.startTime.hour, 21)
            XCTAssertEqual(testConfig.startTime.minute, 0)
            XCTAssertEqual(testConfig.startTime.second, 0)

            XCTAssertEqual(testConfig.endTime.hour, 7)
            XCTAssertEqual(testConfig.endTime.minute, 0)
            XCTAssertEqual(testConfig.endTime.second, 0)
        } catch {
            XCTFail()
        }
    }

    func testEmptyChannelEventConfig() {
        let jsonData: JsonDict = [:]

        do {
            let _ = try ChannelPointConfig(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testChannelEventNoSetting() {
        let jsonData: JsonDict = [
            "time": "08:00:00"
        ]

        do {
            let _ = try ChannelPointConfig(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testChannelEventConfig() {
        let jsonDataIntensity: JsonDict = [
            "time": "08:00:00",
            "intensity": 0.25
        ]

        let jsonDataBrightness: JsonDict = [
            "time": "10:30:00",
            "brightness": 0.30
        ]

        do {
            let testEvent1 = try ChannelPointConfig(json: jsonDataIntensity)
            let testDate1 = ConfigurationTests.dateFormatter.date(from: "08:00:00")!
            let expectedComponents1 = Calendar.current.dateComponents([.hour, .minute, .second], from: testDate1)
            XCTAssertEqual(testEvent1.time, expectedComponents1)
            XCTAssertEqual(testEvent1.setting.asIntensity(withGamma: 2.0), 0.25)

            let testEvent2 = try ChannelPointConfig(json: jsonDataBrightness)
            let testDate2 = ConfigurationTests.dateFormatter.date(from: "10:30:00")!
            let expectedComponents2 = Calendar.current.dateComponents([.hour, .minute, .second], from: testDate2)
            XCTAssertEqual(testEvent2.time, expectedComponents2)
            XCTAssertEqual(testEvent2.setting.asBrightness(withGamma: 2.0), 0.30)
        } catch {
            XCTFail()
        }
    }

    func testEmptyChannelConfig() {
        let jsonData: JsonDict = [:]

        do {
            let _ = try ChannelConfig(token: "TestToken", json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testChannelConfigNoSchedule() {
        let jsonData: JsonDict = [
            "minIntensity": 0.0025
        ]

        do {
            let _ = try ChannelConfig(token: "TestToken", json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testMinChannelConfig() {
        let jsonData: JsonDict = [
            "schedule": [[
                "time": "10:30:00",
                "brightness": 0.30
            ],[
                "time": "11:30:00",
                "brightness": 0.50
            ]]
        ]

        do {
            let testConfig = try ChannelConfig(token: "TestToken", json: jsonData)

            XCTAssertEqual(testConfig.minIntensity, 0.0)
            XCTAssertEqual(testConfig.schedule.count, 2)
        } catch {
            XCTFail()
        }
    }

    func testChannelConfig() {
        let jsonData: JsonDict = [
            "minIntensity": 0.0025,
            "schedule": [[
                "time": "10:30:00",
                "brightness": 0.30
            ],[
                "time": "11:30:00",
                "brightness": 0.50
            ]]
        ]

        do {
            let testConfig = try ChannelConfig(token: "TestToken", json: jsonData)

            XCTAssertEqual(testConfig.minIntensity, 0.0025)
            XCTAssertEqual(testConfig.schedule.count, 2)
        } catch {
            XCTFail()
        }
    }

    func testEmptyConfig() {
        let jsonData: JsonDict = [:]

        do {
            let _ = try Configuration(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testConfigNoHardware() {
        let jsonData: JsonDict = [
            "SIM00": [
                "minIntensity": 0.0025,
                "schedule": [[
                    "time": "10:30:00",
                    "brightness": 0.30
                ],[
                    "time": "11:30:00",
                    "brightness": 0.50
                ]]
            ],
            "SIM01": [
                "minIntensity": 0.0025,
                "schedule": [[
                    "time": "10:30:00",
                    "brightness": 0.30
                ],[
                    "time": "11:30:00",
                    "brightness": 0.50
                ]]
            ]
        ]

        do {
            let _ = try Configuration(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testConfigNoChannels() {
        let jsonData: JsonDict = [
            "hardware": [
                "pwmMode": "simulated",
                "channels": 2
            ]
        ]

        do {
            let _ = try Configuration(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testConfigWrongChannelCount() {
        let jsonData: JsonDict = [
            "hardware": [
                "pwmMode": "simulated",
                "channels": 2
            ],
            "SIM00": [
                "minIntensity": 0.0025,
                "schedule": [[
                    "time": "10:30:00",
                    "brightness": 0.30
                ],[
                    "time": "11:30:00",
                    "brightness": 0.50
                ]]
            ]
        ]

        do {
            let _ = try Configuration(json: jsonData)
            XCTFail()
        } catch {
            // Pass
        }
    }

    func testConfigWithoutOptionals() {
        let jsonData: JsonDict = [
            "user": "pi",
            "hardware": [
                "pwmMode": "simulated",
                "channels": 2
            ],
            "SIM00": [
                "minIntensity": 0.0025,
                "schedule": [[
                    "time": "10:30:00",
                    "brightness": 0.30
                ],[
                    "time": "11:30:00",
                    "brightness": 0.50
                ]]
            ],
            "SIM01": [
                "minIntensity": 0.0025,
                "schedule": [[
                    "time": "10:30:00",
                    "brightness": 0.30
                ],[
                    "time": "11:30:00",
                    "brightness": 0.50
                ]]
            ]
        ]

        do {
            let testConfig = try Configuration(json: jsonData)

            XCTAssertEqual(testConfig.channels.count, 2)
        } catch {
            XCTFail()
        }
    }

    func testConfigWithOptionals() {
        let jsonData: JsonDict = [
            "hardware": [
                "pwmMode": "simulated",
                "channels": 2
            ],
            "lunarCycle": [
                "start": "21:00:00",
                "end": "07:00:00"
            ],
            "SIM00": [
                "minIntensity": 0.0025,
                "schedule": [[
                    "time": "10:30:00",
                    "brightness": 0.30
                    ],[
                        "time": "11:30:00",
                        "brightness": 0.50
                    ]]
            ],
            "SIM01": [
                "minIntensity": 0.0025,
                "schedule": [[
                    "time": "10:30:00",
                    "brightness": 0.30
                    ],[
                        "time": "11:30:00",
                        "brightness": 0.50
                    ]]
            ]
        ]

        do {
            let testConfig = try Configuration(json: jsonData)

            XCTAssertEqual(testConfig.channels.count, 2)
        } catch {
            XCTFail()
        }
    }

    static public let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()

    static var allTests = [
        // Hardware Config
        ("testEmptyHardwareConfig", testEmptyHardwareConfig),
        ("testMinHardwareConfig", testMinHardwareConfig),
        ("testHardwareConfig", testHardwareConfig),

        // Lunar Config
        ("testEmptyLunarConfig", testEmptyLunarConfig),
        ("testMinLunarConfig", testMinLunarConfig),

        // Channel Events
        ("testEmptyChannelEventConfig", testEmptyChannelEventConfig),
        ("testChannelEventNoSetting", testChannelEventNoSetting),
        ("testChannelEventConfig", testChannelEventConfig),

        // Channel Config
        ("testEmptyChannelConfig", testEmptyChannelConfig),
        ("testChannelConfigNoSchedule", testChannelConfigNoSchedule),
        ("testMinChannelConfig", testMinChannelConfig),
        ("testChannelConfig", testChannelConfig),

        // Configuration
        ("testEmptyConfig", testEmptyConfig),
        ("testConfigNoHardware", testConfigNoHardware),
        ("testConfigNoChannels", testConfigNoChannels),
        ("testConfigWrongChannelCount", testConfigWrongChannelCount),
        ("testConfigWithoutOptionals", testConfigWithoutOptionals),
        ("testCOnfigWithOptionals", testConfigWithOptionals)
    ]
}
