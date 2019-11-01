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

struct DayTime: Codable {
    enum DecodeError: Error {
        case unableToParse
    }
    
    var dateComponents: DateComponents

    private static let Formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedString = try container.decode(String.self)
        guard let parsedTime = DayTime.Formatter.date(from: decodedString) else {
            throw DecodeError.unableToParse
        }
        dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedTime)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let tempDate = Calendar.current.nextDate(after: Date(),
                                             matching: dateComponents,
                                             matchingPolicy: .nextTime,
                                             repeatedTimePolicy: .first,
                                             direction: .forward)!
        let encodedString = DayTime.Formatter.string(from: tempDate)
        try container.encode(encodedString)
    }
}

// MARK: Wrapper for DateComponent Access

extension DayTime {
    var hour: Int? { get { dateComponents.hour }}
    var minute: Int? { get { dateComponents.minute }}
    var second: Int? { get { dateComponents.second }}
}
