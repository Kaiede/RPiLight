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

class SwiftExtensionsTests: XCTestCase {
    func testCalcNextDateCustom() {
        let testExpectations = [
            // Start Time, Target Time, Search Direction
            ( "08:00:00", "08:00:00", Calendar.SearchDirection.forward ),
            ( "08:00:00", "08:00:00", Calendar.SearchDirection.backward ),
            ( "08:00:00", "08:30:00", Calendar.SearchDirection.forward ),
            ( "08:00:00", "08:30:00", Calendar.SearchDirection.backward )
        ]

        for (startString, targetString, searchDirection) in testExpectations {
            let startDate = SwiftExtensionsTests.dateFormatter.date(from: startString)!
            let targetDate = SwiftExtensionsTests.dateFormatter.date(from: targetString)!
            let targetTime = Calendar.current.dateComponents([.hour, .minute, .second], from: targetDate)

            let calculatedDate = targetTime.calcNextDateCustom(after: startDate, direction: searchDirection)!

            XCTAssertNotEqual(startDate, calculatedDate)
            switch searchDirection {
            case .backward:
                XCTAssertLessThan(calculatedDate, startDate)
            case .forward:
                XCTAssertGreaterThan(calculatedDate, startDate)
            }

            // Apple-only: Compare against real implementation
            #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
            let calculatedDateMac = Calendar.current.nextDate(after: startDate,
                                                              matching: targetTime,
                                                              matchingPolicy: .nextTime,
                                                              repeatedTimePolicy: .first,
                                                              direction: searchDirection)!

            XCTAssertEqual(calculatedDate, calculatedDateMac)
            #endif
        }
    }

    static var allTests = [
        ("testCalcNextDateCustom", testCalcNextDateCustom)
    ]

    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()
}

