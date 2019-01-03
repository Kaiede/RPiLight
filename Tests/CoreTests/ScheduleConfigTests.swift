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
            XCTAssertEqual(channelSchedule.schedule[0].setting.asBrightness(withGamma: 1.8), 0.30)
            XCTAssertEqual(channelSchedule.schedule[1].setting.asBrightness(withGamma: 1.8), 0.50)
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
            XCTAssertEqual(channelSchedule.schedule.count, 2)
            XCTAssertEqual(channelSchedule.schedule[0].setting.asBrightness(withGamma: 1.8), 0.30)
            XCTAssertEqual(channelSchedule.schedule[1].setting.asBrightness(withGamma: 1.8), 0.50)
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
                XCTAssertEqual(brightness, 0.25)
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
                XCTAssertEqual(intensity, 0.25)
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

    static var allTests = [
        ("testLunarSchedule_Empty", testLunarSchedule_Empty),
        ("testLunarSchedule_Partial", testLunarSchedule_Partial),
        ("testLunarSchedule_Complete", testLunarSchedule_Complete),
        ("testSchedulePoint_Empty", testSchedulePoint_Empty),
        ("testSchedulePoint_TooManySecrets", testSchedulePoint_TooManySecrets),
        ("testSchedulePoint_Brightness", testSchedulePoint_Brightness),
        ("testSchedulePoint_Intensity", testSchedulePoint_Intensity),
        ("testCompleteSchedule_Empty", testCompleteSchedule_Empty),
        ("testCompleteSchedule", testCompleteSchedule)
    ]
}
