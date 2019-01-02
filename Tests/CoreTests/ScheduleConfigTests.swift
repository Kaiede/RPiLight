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
    func testEmptyScheduleConfiguration() {
    //     let jsonData: JsonDictionary = [:]
    //     do {
    //         let decoder = JSONDecoder()
    //         let _ = try decoder.decode(ScheduleConfiguration.self, from: jsonData)
    //         XCTFail("Empty configuration should throw, because of missing properties: user, pwmMode, board")
    //     } catch {
    //         // Pass
    //     }
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
            "time": "08:00:00",
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
            "time": "08:00:00",
            "brightness": 0.25
        ]
        do {
            let decoder = JSONDecoder()
            let point = try decoder.decode(SchedulePoint.self, from: jsonData)
            //XCTAssertEqual(point.time, "test_user")
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
            "time": "08:00:00",
            "intensity": 0.25
        ]
        do {
            let decoder = JSONDecoder()
            let point = try decoder.decode(SchedulePoint.self, from: jsonData)
            //XCTAssertEqual(point.time, "test_user")
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

    static var allTests = [
        ("testEmptyScheduleConfiguration", testEmptyScheduleConfiguration),
        ("testSchedulePoint_Empty", testSchedulePoint_Empty),
        ("testSchedulePoint_TooManySecrets", testSchedulePoint_TooManySecrets),
        ("testSchedulePoint_Brightness", testSchedulePoint_Brightness),
        ("testSchedulePoint_Intensity", testSchedulePoint_Intensity)
    ]
}
