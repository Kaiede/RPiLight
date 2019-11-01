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

import Foundation
import XCTest
@testable import LED

typealias JsonDictionary = [String: Any]

extension JSONDecoder {
    // Helper function for testing.
    // Enables using Dictionaries directly
    func decode<T>(_ type: T.Type, from dict: JsonDictionary) throws -> T where T : Decodable {
        let data: Data = try JSONSerialization.data(withJSONObject: dict)
        return try self.decode(type, from: data)
    }
}

struct MockCodable: Codable {
    var brightness: Brightness
    var intensity: Intensity
    var gamma: Gamma
}

class TypeTests: XCTestCase {
    func testFlatGammaConversion() {
        let gamma = Gamma(1.0)
        let intensity = Intensity(0.5)
        let brightness = Brightness(intensity, gamma: gamma)
        let intensity2 = Intensity(brightness, gamma: gamma)

        XCTAssertEqual(brightness.rawValue, intensity.rawValue)
        XCTAssertEqual(intensity2.rawValue, brightness.rawValue)
    }

    func testCurvedGammaConversion() {
        let gamma = Gamma(2.0)
        let brightness = Brightness(0.5)
        let intensity = Intensity(brightness, gamma: gamma)
        let brightness2 = Brightness(intensity, gamma: gamma)

        XCTAssertEqual(intensity.rawValue, 0.25)
        XCTAssertEqual(brightness2.rawValue, brightness.rawValue)
    }

    func testCodableTypes() {
        let jsonData = [
            "brightness": 1.0,
            "intensity": 0.5,
            "gamma": 2.2
        ]

        do {
            let decoder = JSONDecoder()
            let codable = try decoder.decode(MockCodable.self, from: jsonData)
            XCTAssertEqual(codable.brightness, Brightness(1.0))
            XCTAssertEqual(codable.intensity, Intensity(0.5))
            XCTAssertEqual(codable.gamma, Gamma(2.2))
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testIntensitySteps() {
        let maxSteps: UInt = 4095
        XCTAssertEqual(Intensity(0.0).toSteps(max: maxSteps), 0) // Can Hit True Zero
        XCTAssertEqual(Intensity(0.25).toSteps(max: maxSteps), 1023) // Rounds Down
        XCTAssertEqual(Intensity(1.0).toSteps(max: maxSteps), 4095) // Can Hit True Max
    }
    
    func testIntensityPercent() {
        XCTAssertEqual(Intensity(0.0).toPercentage(), 0.0) // Can Hit True Zero
        XCTAssertEqual(Intensity(0.25).toPercentage(), 25.0)
        XCTAssertEqual(Intensity(1.0).toPercentage(), 100.0) // Can Hit True Max
    }

    static var allTests = [
        ("testFlatGammaConversion", testFlatGammaConversion),
        ("testCurvedGammaConversion", testCurvedGammaConversion),
        ("testCodableTypes", testCodableTypes),
        ("testIntensitySteps", testIntensitySteps),
        ("testIntensityPercent", testIntensityPercent),
    ]
}
