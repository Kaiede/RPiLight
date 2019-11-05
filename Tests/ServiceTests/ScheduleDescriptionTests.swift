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
import Yams
@testable import Service

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length

class ScheduleDescriptionTests: XCTestCase {
    func testLunarSchedule_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            _ = try decoder.decode(LunarCycleDescription.self, from: jsonData)
            XCTFail("Empty is invalid")
        } catch {
            // Pass
        }
    }

    func testLunarSchedule_Partial() {
        let jsonData: JsonDictionary = [
            "start": "20:30:00"
        ]
        do {
            let decoder = JSONDecoder()
            _ = try decoder.decode(LunarCycleDescription.self, from: jsonData)
            XCTFail("Partial is invalid")
        } catch {
            // Pass
        }
    }

    func testLunarSchedule_Complete() {
        let jsonData: JsonDictionary = [
            "start": "20:30:00",
            "end": "07:30:00"
        ]
        do {
            let decoder = JSONDecoder()
            let lunarSchedule = try decoder.decode(LunarCycleDescription.self, from: jsonData)

            XCTAssertEqual(lunarSchedule.start.hour, 20)
            XCTAssertEqual(lunarSchedule.start.minute, 30)
            XCTAssertEqual(lunarSchedule.start.second, 0)

            XCTAssertEqual(lunarSchedule.end.hour, 7)
            XCTAssertEqual(lunarSchedule.end.minute, 30)
            XCTAssertEqual(lunarSchedule.end.second, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testChannelSchedule_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            _ = try decoder.decode(ChannelScheduleDescription.self, from: jsonData)
            XCTFail("Empty is invalid")
        } catch {
            // Pass
        }
    }

    func testChannelSchedule_OptionalIntensity() {
        let jsonData: JsonDictionary = [
            "steps": [[
                "time": "10:30:00",
                "brightness": 0.30
            ], [
                "time": "11:30:00",
                "brightness": 0.50
            ]]
        ]
        do {
            let decoder = JSONDecoder()
            let channelSchedule = try decoder.decode(ChannelScheduleDescription.self, from: jsonData)

            // Channel Specific Settings
            XCTAssertNil(channelSchedule.minIntensity)

            // Sanity Check the Schedule Itself
            XCTAssertEqual(channelSchedule.steps.count, 2)
            XCTAssertEqual(channelSchedule.steps[0].brightness, 0.30)
            XCTAssertEqual(channelSchedule.steps[1].brightness, 0.50)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testChannelSchedule_Complete() {
        let jsonData: JsonDictionary = [
            "min-intensity": 0.0025,
            "steps": [[
                "time": "10:30:00",
                "brightness": 0.30
            ], [
                "time": "11:30:00",
                "brightness": 0.50
            ]]
        ]
        do {
            let decoder = JSONDecoder()
            let channelSchedule = try decoder.decode(ChannelScheduleDescription.self, from: jsonData)

            // Channel Specific Settings
            XCTAssertEqual(channelSchedule.minIntensity, 0.0025)

            // Sanity Check the Schedule Itself
            XCTAssertEqual(channelSchedule.steps.count, 2)
            XCTAssertEqual(channelSchedule.steps[0].brightness, 0.30)
            XCTAssertEqual(channelSchedule.steps[1].brightness, 0.50)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testSchedulePoint_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            _ = try decoder.decode(ScheduleStepDescription.self, from: jsonData)
            XCTFail("Empty is invalid")
        } catch {
            // Pass
        }
    }

    func testSchedulePoint_Brightness() {
        let jsonData: JsonDictionary = [
            "time": "08:30:25",
            "brightness": 0.25
        ]
        do {
            let decoder = JSONDecoder()
            let point = try decoder.decode(ScheduleStepDescription.self, from: jsonData)
            XCTAssertEqual(point.time.hour, 8)
            XCTAssertEqual(point.time.minute, 30)
            XCTAssertEqual(point.time.second, 25)

            XCTAssertNil(point.intensity)
            XCTAssertEqual(point.brightness, 0.25)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testSchedulePoint_Intensity() {
        let jsonData: JsonDictionary = [
            "time": "08:30:25",
            "intensity": 0.25
        ]
        do {
            let decoder = JSONDecoder()
            let point = try decoder.decode(ScheduleStepDescription.self, from: jsonData)
            XCTAssertEqual(point.time.hour, 8)
            XCTAssertEqual(point.time.minute, 30)
            XCTAssertEqual(point.time.second, 25)

            XCTAssertEqual(point.intensity, 0.25)
            XCTAssertNil(point.brightness)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testCompleteSchedule_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            _ = try decoder.decode(ScheduleDescription.self, from: jsonData)

            XCTFail("Empty schedule isn't valid")
        } catch {
            // Pass
        }
    }

    func testCompleteSchedule() {
        let jsonData: JsonDictionary = [
            "lunar-cycle": [
                "start": "21:00:00",
                "end": "07:00:00"
            ],
            "schedule": [
                "SIM00": [
                    "min-intensity": 0.0025,
                    "steps": [[
                        "time": "10:30:00",
                        "brightness": 0.30
                        ], [
                            "time": "11:30:00",
                            "brightness": 0.50
                        ]]
                ],
                "SIM01": [
                    "min-intensity": 0.0025,
                    "steps": [[
                        "time": "10:30:00",
                        "brightness": 0.30
                        ], [
                            "time": "11:30:00",
                            "brightness": 0.50
                        ]]
                ]
            ]
        ]
        do {
            let decoder = JSONDecoder()
            let schedule = try decoder.decode(ScheduleDescription.self, from: jsonData)

            // Sanity Check the Channels
            XCTAssertEqual(schedule.schedule.count, 2)
            XCTAssertEqual(schedule.schedule["SIM00"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.schedule["SIM00"]?.steps.count, 2)
            XCTAssertEqual(schedule.schedule["SIM01"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.schedule["SIM01"]?.steps.count, 2)

            // Sanity Check the Lunar Schedule
            XCTAssertNotNil(schedule.lunarCycle)
            XCTAssertEqual(schedule.lunarCycle?.start.hour, 21)
            XCTAssertEqual(schedule.lunarCycle?.start.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.start.second, 0)
            XCTAssertEqual(schedule.lunarCycle?.end.hour, 7)
            XCTAssertEqual(schedule.lunarCycle?.end.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.end.second, 0)

            // Did the Channel Schedules Parse?
        } catch {
            XCTFail("\(error)")
        }
    }

    func testCompleteSchedule_Example_Json() {
        let jsonString = """
        {
            "lunar-cycle": {
                "start": "21:00:00",
                "end": "07:00:00"
            },

            "schedule": {
                "primary": {
                    "min-intensity": 0.0025,
                    "steps": [
                        { "time": "08:00:00", "brightness": 0.0 },
                        { "time": "08:30:00", "brightness": 0.25 },
                        { "time": "12:00:00", "brightness": 0.25 },
                        { "time": "14:00:00", "brightness": 0.50 },
                        { "time": "18:00:00", "brightness": 0.50 },
                        { "time": "20:00:00", "brightness": 0.10 },
                        { "time": "22:30:00", "brightness": 0.10 },
                        { "time": "23:00:00", "brightness": 0.0 }
                    ]
                },

                "secondary": {
                    "min-intensity": 0.0025,
                    "steps": [
                        { "time": "08:00:00", "brightness": 0.0 },
                        { "time": "08:30:00", "brightness": 0.30 },
                        { "time": "18:00:00", "brightness": 0.30 },
                        { "time": "20:00:00", "brightness": 0.15 },
                        { "time": "22:30:00", "brightness": 0.15 },
                        { "time": "23:00:00", "brightness": 0.0 }
                    ]
                }
            }
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        do {
            let decoder = JSONDecoder()
            let schedule = try decoder.decode(ScheduleDescription.self, from: jsonData)

            // Sanity Check the Channels
            XCTAssertEqual(schedule.schedule.count, 2)
            XCTAssertEqual(schedule.schedule["primary"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.schedule["primary"]?.steps.count, 8)
            XCTAssertEqual(schedule.schedule["secondary"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.schedule["secondary"]?.steps.count, 6)

            // Sanity Check the Lunar Schedule
            XCTAssertNotNil(schedule.lunarCycle)
            XCTAssertEqual(schedule.lunarCycle?.start.hour, 21)
            XCTAssertEqual(schedule.lunarCycle?.start.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.start.second, 0)
            XCTAssertEqual(schedule.lunarCycle?.end.hour, 7)
            XCTAssertEqual(schedule.lunarCycle?.end.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.end.second, 0)

            // Did the Channel Schedules Parse?
        } catch {
            XCTFail("\(error)")
        }
    }

    func testCompleteSchedule_Example_Yaml() {
        let yamlString = """
        lunar-cycle:
            start: 21:00:00
            end: 07:00:00

        schedule:
            primary:
                min-intensity: 0.0025
                steps:
                    - { time: 08:00:00, brightness: 0.0 }
                    - { time: 08:30:00, brightness: 0.25 }
                    - { time: 12:00:00, brightness: 0.25 }
                    - { time: 14:00:00, brightness: 0.50 }
                    - { time: 18:00:00, brightness: 0.50 }
                    - { time: 20:00:00, brightness: 0.10 }
                    - { time: 22:30:00, brightness: 0.10 }
                    - { time: 23:00:00, brightness: 0.0 }

            secondary:
                min-intensity: 0.0025
                steps:
                    - { time: 08:00:00, brightness: 0.0 }
                    - { time: 08:30:00, brightness: 0.30 }
                    - { time: 18:00:00, brightness: 0.30 }
                    - { time: 20:00:00, brightness: 0.15 }
                    - { time: 22:30:00, brightness: 0.15 }
                    - { time: 23:00:00, brightness: 0.0 }
        """

        do {
            let decoder = YAMLDecoder()
            let schedule = try decoder.decode(ScheduleDescription.self, from: yamlString)

            // Sanity Check the Channels
            XCTAssertEqual(schedule.schedule.count, 2)
            XCTAssertEqual(schedule.schedule["primary"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.schedule["primary"]?.steps.count, 8)
            XCTAssertEqual(schedule.schedule["secondary"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.schedule["secondary"]?.steps.count, 6)

            // Sanity Check the Lunar Schedule
            XCTAssertNotNil(schedule.lunarCycle)
            XCTAssertEqual(schedule.lunarCycle?.start.hour, 21)
            XCTAssertEqual(schedule.lunarCycle?.start.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.start.second, 0)
            XCTAssertEqual(schedule.lunarCycle?.end.hour, 7)
            XCTAssertEqual(schedule.lunarCycle?.end.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.end.second, 0)

            // Did the Channel Schedules Parse?
        } catch {
            XCTFail("\(error)")
        }
    }

    static var allTests = [
        ("testLunarSchedule_Empty", testLunarSchedule_Empty),
        ("testLunarSchedule_Partial", testLunarSchedule_Partial),
        ("testLunarSchedule_Complete", testLunarSchedule_Complete),
        ("testChannelSchedule_Empty", testChannelSchedule_Empty),
        ("testChannelSchedule_OptionalIntensity", testChannelSchedule_OptionalIntensity),
        ("testChannelSchedule_Complete", testChannelSchedule_Complete),
        ("testSchedulePoint_Empty", testSchedulePoint_Empty),
        ("testSchedulePoint_Brightness", testSchedulePoint_Brightness),
        ("testSchedulePoint_Intensity", testSchedulePoint_Intensity),
        ("testCompleteSchedule_Empty", testCompleteSchedule_Empty),
        ("testCompleteSchedule", testCompleteSchedule),
        ("testCompleteSchedule_Example_Json", testCompleteSchedule_Example_Json),
        ("testCompleteSchedule_Example_Yaml", testCompleteSchedule_Example_Yaml)
    ]
}
