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

class ScheduleConfigTests: XCTestCase {
    func testLunarSchedule_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(LunarSchedule.self, from: jsonData)
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
            let _ = try decoder.decode(LunarSchedule.self, from: jsonData)
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
            let lunarSchedule = try decoder.decode(LunarSchedule.self, from: jsonData)

            XCTAssertEqual(lunarSchedule.startTime.hour, 20)
            XCTAssertEqual(lunarSchedule.startTime.minute, 30)
            XCTAssertEqual(lunarSchedule.startTime.second, 0)

            XCTAssertEqual(lunarSchedule.endTime.hour, 7)
            XCTAssertEqual(lunarSchedule.endTime.minute, 30)
            XCTAssertEqual(lunarSchedule.endTime.second, 0)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testChannelSchedule_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(ChannelSchedule.self, from: jsonData)
            XCTFail("Empty is invalid")
        } catch {
            // Pass
        }
    }

    func testChannelSchedule_OptionalIntensity() {
        let jsonData: JsonDictionary = [
            "schedule": [[
                "time": "10:30:00",
                "brightness": 0.30
            ],[
                "time": "11:30:00",
                "brightness": 0.50
            ]]
        ]
        do {
            let decoder = JSONDecoder()
            let channelSchedule = try decoder.decode(ChannelSchedule.self, from: jsonData)

            // Channel Specific Settings
            XCTAssertEqual(channelSchedule.minIntensity, 0.0)

            // Sanity Check the Schedule Itself
            XCTAssertEqual(channelSchedule.schedule.count, 2)
            let gamma = Gamma(1.8)
            XCTAssertEqual(Brightness(setting: channelSchedule.schedule[0].setting, gamma: gamma), Brightness(0.30))
            XCTAssertEqual(Brightness(setting: channelSchedule.schedule[1].setting, gamma: gamma), Brightness(0.50))
        } catch {
            XCTFail("\(error)")
        }
    }

    func testChannelSchedule_Complete() {
        let jsonData: JsonDictionary = [
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
            let decoder = JSONDecoder()
            let channelSchedule = try decoder.decode(ChannelSchedule.self, from: jsonData)

            // Channel Specific Settings
            XCTAssertEqual(channelSchedule.minIntensity, 0.0025)

            // Sanity Check the Schedule Itself
            let gamma = Gamma(1.8)
            XCTAssertEqual(channelSchedule.schedule.count, 2)
            XCTAssertEqual(Brightness(setting: channelSchedule.schedule[0].setting, gamma: gamma), Brightness(0.30))
            XCTAssertEqual(Brightness(setting: channelSchedule.schedule[1].setting, gamma: gamma), Brightness(0.50))
        } catch {
            XCTFail("\(error)")
        }
    }

    func testSchedulePoint_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(SchedulePoint.self, from: jsonData)
            XCTFail("Empty is invalid")
        } catch {
            // Pass
        }
    }

    func testSchedulePoint_TooManySecrets() {
        let jsonData: JsonDictionary = [
            "time": "08:30:25",
            "intensity": 0.25,
            "brightness": 0.3
        ]
        do {
            let decoder = JSONDecoder()
            let _ = try decoder.decode(SchedulePoint.self, from: jsonData)
            XCTFail("Both intensity and brightness being set is invalid")
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
            let point = try decoder.decode(SchedulePoint.self, from: jsonData)
            XCTAssertEqual(point.time.hour, 8)
            XCTAssertEqual(point.time.minute, 30)
            XCTAssertEqual(point.time.second, 25)

            switch(point.setting) {
            case .brightness(let brightness):
                XCTAssertEqual(brightness.rawValue, 0.25)
            case .intensity(_):
                XCTFail("Didn't expect intensity")                
            }
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
            let point = try decoder.decode(SchedulePoint.self, from: jsonData)
            XCTAssertEqual(point.time.hour, 8)
            XCTAssertEqual(point.time.minute, 30)
            XCTAssertEqual(point.time.second, 25)

            switch(point.setting) {
            case .brightness(_):
                XCTFail("Didn't expect brightness")
            case .intensity(let intensity):
                XCTAssertEqual(intensity.rawValue, 0.25)
            }
        } catch {
            XCTFail("\(error)")
        }
    }

    func testCompleteSchedule_Empty() {
        let jsonData: JsonDictionary = [:]
        do {
            let decoder = JSONDecoder()
            let schedule = try decoder.decode(Schedule.self, from: jsonData)

            // Empty Schedule is Empty
            XCTAssertEqual(schedule.channels.count, 0)
            XCTAssertNil(schedule.lunarCycle)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testCompleteSchedule() {
        let jsonData: JsonDictionary = [
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
            let decoder = JSONDecoder()
            let schedule = try decoder.decode(Schedule.self, from: jsonData)

            // Sanity Check the Channels
            XCTAssertEqual(schedule.channels.count, 2)
            XCTAssertEqual(schedule.channels["SIM00"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.channels["SIM00"]?.schedule.count, 2)
            XCTAssertEqual(schedule.channels["SIM01"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.channels["SIM01"]?.schedule.count, 2)

            // Sanity Check the Lunar Schedule
            XCTAssertNotNil(schedule.lunarCycle)
            XCTAssertEqual(schedule.lunarCycle?.startTime.hour, 21)
            XCTAssertEqual(schedule.lunarCycle?.startTime.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.startTime.second, 0)
            XCTAssertEqual(schedule.lunarCycle?.endTime.hour, 7)
            XCTAssertEqual(schedule.lunarCycle?.endTime.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.endTime.second, 0)

            // Did the Channel Schedules Parse?
        } catch {
            XCTFail("\(error)")
        }
    }

    func testCompleteSchedule_Example() {
        let jsonString = """
        {
            "lunarCycle": {
                "start": "21:00:00",
                "end": "07:00:00"
            },

            "primary": {
                "minIntensity": 0.0025,
                "schedule": [
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
                "minIntensity": 0.0025,
                "schedule": [
                    { "time": "08:00:00", "brightness": 0.0 },
                    { "time": "08:30:00", "brightness": 0.30 },
                    { "time": "18:00:00", "brightness": 0.30 },
                    { "time": "20:00:00", "brightness": 0.15 },
                    { "time": "22:30:00", "brightness": 0.15 },
                    { "time": "23:00:00", "brightness": 0.0 }
                ]
            }
        }
        """

        let jsonData = jsonString.data(using: .utf8)!
        do {
            let decoder = JSONDecoder()
            let schedule = try decoder.decode(Schedule.self, from: jsonData)

            // Sanity Check the Channels
            XCTAssertEqual(schedule.channels.count, 2)
            XCTAssertEqual(schedule.channels["primary"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.channels["primary"]?.schedule.count, 8)
            XCTAssertEqual(schedule.channels["secondary"]?.minIntensity, 0.0025)
            XCTAssertEqual(schedule.channels["secondary"]?.schedule.count, 6)

            // Sanity Check the Lunar Schedule
            XCTAssertNotNil(schedule.lunarCycle)
            XCTAssertEqual(schedule.lunarCycle?.startTime.hour, 21)
            XCTAssertEqual(schedule.lunarCycle?.startTime.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.startTime.second, 0)
            XCTAssertEqual(schedule.lunarCycle?.endTime.hour, 7)
            XCTAssertEqual(schedule.lunarCycle?.endTime.minute, 0)
            XCTAssertEqual(schedule.lunarCycle?.endTime.second, 0)

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
        ("testSchedulePoint_TooManySecrets", testSchedulePoint_TooManySecrets),
        ("testSchedulePoint_Brightness", testSchedulePoint_Brightness),
        ("testSchedulePoint_Intensity", testSchedulePoint_Intensity),
        ("testCompleteSchedule_Empty", testCompleteSchedule_Empty),
        ("testCompleteSchedule", testCompleteSchedule),
        ("testCompleteSchedule_Example", testCompleteSchedule_Example)
    ]
}
