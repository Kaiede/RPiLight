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

import Logging
import LED

protocol LayerPoint {
    var time: DayTime { get }
    var brightness: Brightness { get }
}

class Layer: ChannelLayer {
    private let identifier: String
    private let points: [LayerPoint]

    // Current State
    private(set) var activeIndex: Int
    private(set) var activeSegment: LayerSegment

    init(identifier: String, points: [LayerPoint], startTime: Date) {
        self.identifier = identifier
        self.points = points
        (self.activeIndex, self.activeSegment) = Layer.activeSegment(forDate: startTime, withPoints: points)
        log.info({
            let startString = logTime.string(from: activeSegment.startDate)
            let endString = logTime.string(from: activeSegment.endDate)
            return "Initial Segment Guess: [\(identifier)] \(activeSegment.range) \(startString) -> \(endString)"
        }())
    }

    func segment(forDate date: Date) -> ChannelSegment {
        let (_, activeSegment) = Layer.activeSegment(forDate: date, withPoints: self.points)

        return activeSegment
    }

    func lightLevel(forDate now: Date) -> Brightness {
        if now >= self.activeSegment.endDate || now < self.activeSegment.startDate {
            (self.activeIndex, self.activeSegment) = Layer.activeSegment(forDate: now, withPoints: points)
            log.info({
                let startString = logTime.string(from: activeSegment.startDate)
                let endString = logTime.string(from: activeSegment.endDate)
                return "Switched to Segment: [\(identifier)] \(activeSegment.range) \(startString) -> \(endString)"
            }())
        }

        return self.activeSegment.lightLevel(forDate: now)
    }

    private static func findPreviousStartTime(forDate date: Date, withPoints points: [LayerPoint]) -> (Int, Date) {
        let dates: [Date] = points.map({
            guard let calculatedDate: Date = $0.time.calcNextDate(after: date, direction: .backward) else {
                fatalError("Could not calculate the time \($0.time)  previous to \(date)")
            }
            return calculatedDate
        })

        guard let (index, date) = dates.enumerated().max(by: { $0.element < $1.element }) else {
            fatalError("Could not calculate the maximum of the dates")
        }

        return (index, date)
    }

    private static func activeSegment(forDate date: Date, withPoints points: [LayerPoint]) -> (Int, LayerSegment) {
       let (activeIndex, activeDate) = findPreviousStartTime(forDate: date, withPoints: points)

        let activeSegment = Layer.segment(forIndex: activeIndex, withStartDate: activeDate, points: points)
        return (activeIndex, activeSegment)
    }

    private static func segment(forIndex index: Int,
                                withStartDate startDate: Date,
                                points: [LayerPoint]) -> LayerSegment {
        let nextIndex = (index + 1) % points.count

        guard let endDate = points[nextIndex].time.calcNextDate(after: startDate) else {
            fatalError("Could not calculate next time \(points[nextIndex].time), after date \(startDate)")
        }
        let segmentRange = SegmentRange(origin: points[index].brightness, end: points[nextIndex].brightness)
        return LayerSegment(startDate: startDate, endDate: endDate, range: segmentRange)
    }
}

struct LayerSegment: ChannelSegment {
    var range: SegmentRange
    var startDate: Date
    var endDate: Date

    var startBrightness: Brightness {
        return range.origin
    }

    var endBrightness: Brightness {
        return range.end
    }

    var timeDelta: TimeInterval {
        return self.endDate.timeIntervalSince(self.startDate)
    }

    init(startDate: Date, endDate: Date, range: SegmentRange) {
        self.startDate = startDate
        self.endDate = endDate
        self.range = range
    }

    func lightLevel(forDate now: Date) -> Brightness {
        return self.range.bound(self.interpolateBrightness(forDate: now))
    }
}

struct SegmentRange: CustomStringConvertible {
    var origin: Brightness
    var end: Brightness

    var delta: Double {
        return self.end.rawValue - self.origin.rawValue
    }

    init(origin: Brightness, end: Brightness) {
        self.origin = origin
        self.end = end
    }

    func bound(_ value: Brightness) -> Brightness {
        let highBound = max(self.origin, self.end)
        let lowBound = min(self.origin, self.end)
        return max(lowBound, min(highBound, value))
    }

    var description: String {
        return "(\(self.origin.rawValue), ∆\(self.delta))"
    }
}
