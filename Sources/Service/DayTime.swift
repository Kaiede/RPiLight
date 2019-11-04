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

public struct DayTime: Codable {
    enum DecodeError: Error {
        case unableToParse
    }
    
    public internal(set) var dateComponents: DateComponents

    private static let Formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()

    public init(from date: Date, calendar: Calendar = Calendar.current) {
        self.dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
    }

    public init(_ components: DateComponents) {
        self.dateComponents = components.asTimeOfDay()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedString = try container.decode(String.self)
        guard let parsedTime = DayTime.Formatter.date(from: decodedString) else {
            throw DecodeError.unableToParse
        }
        dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedTime)
    }

    public func encode(to encoder: Encoder) throws {
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

extension DayTime: Equatable {
    public static func == (lhs: DayTime, rhs: DayTime) -> Bool {
        return lhs.dateComponents == rhs.dateComponents
    }
}

extension DayTime: CustomStringConvertible {
    public var description: String {
        return self.dateComponents.description
    }
}

extension DayTime: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.dateComponents.debugDescription
    }
}


// MARK: Wrapper for DateComponent Access

public extension DayTime {
    var hour: Int? { get { return dateComponents.hour }}
    var minute: Int? { get { return dateComponents.minute }}
    var second: Int? { get { return dateComponents.second }}
}

public extension DayTime {
    func calcNextDate(after date: Date, direction: Calendar.SearchDirection = .forward) -> Date? {
        #if swift(>=5.0)
            return Calendar.current.nextDate(after: date,
                                             matching: self.dateComponents,
                                             matchingPolicy: .nextTime,
                                             repeatedTimePolicy: .first,
                                             direction: direction)
        #else
            #if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
                return Calendar.current.nextDate(after: date,
                                                matching: self.dateComponents,
                                                matchingPolicy: .nextTime,
                                                repeatedTimePolicy: .first,
                                                direction: direction)
            #elseif os(Linux)
                return self.calcNextDateCustom(after: date, direction: direction)
            #else
                fatalError("No Implementation Available for this OS")
            #endif
        #endif

    }
    
    // This is a custom implementation aimed at Linux. It is specialized for the puposes of this package,
    // but may not be very relevant for any other package.
    internal func calcNextDateCustom(after date: Date, direction: Calendar.SearchDirection = .forward) -> Date? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        var dateComponentAsDayTime = self.dateComponents.asTimeOfDay()
        guard let targetDate = calendar.date(byAdding: dateComponentAsDayTime, to: startOfDay) else { return nil }
        switch direction {
        case .forward:
            if targetDate <= date { dateComponentAsDayTime.day = 1 }
        case .backward:
            if targetDate >= date { dateComponentAsDayTime.day = -1 }
        }

        return calendar.date(byAdding: dateComponentAsDayTime, to: startOfDay, wrappingComponents: false)
    }
}

// MARK: Internal Helper Functions

fileprivate extension DateComponents {
    func asTimeOfDay() -> DateComponents {
        return DateComponents(calendar: self.calendar,
                              timeZone: self.timeZone,
                              hour: self.hour,
                              minute: self.minute,
                              second: self.second,
                              nanosecond: self.nanosecond)
    }
}
