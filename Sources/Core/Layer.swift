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
import PWM

protocol LayerPoint {
    var time: DateComponents { get }
    var brightness: Double { get }
}

class Layer: ChannelLayer {
    private let points: [LayerPoint]

    // Current State
    private(set) var activeIndex: Int
    private(set) var activeSegment: LayerSegment

    init(points: [LayerPoint], startTime: Date) {
        self.points = points
        (self.activeIndex, self.activeSegment) = Layer.activeSegment(forDate: startTime, withPoints: points)
    }

    func segment(forDate date: Date) -> ChannelSegment {
        let (_, activeSegment) = Layer.activeSegment(forDate: date, withPoints: self.points)
        
        return activeSegment
    }
    
    func lightLevel(forDate now: Date) -> Double {
        if now > self.activeSegment.endDate || now < self.activeSegment.startDate {
            (self.activeIndex, self.activeSegment) = Layer.activeSegment(forDate: now, withPoints: points)
        }

        return self.activeSegment.lightLevel(forDate: now)
    }

    private static func activeSegment(forDate date: Date, withPoints points: [LayerPoint]) -> (Int, LayerSegment) {
        let (activeIndex, activeDate) = points.map({ $0.time.calcNextDate(after: date, direction: .backward)! })
            .enumerated()
            .max(by: { $0.element < $1.element })!

        let activeSegment = Layer.segment(forIndex: activeIndex, withStartDate: activeDate, points: points)
        
        Log.withInfo {
            let formatter = Log.dateFormatter
            Log.info("Switched to Segment: [\(activeIndex)] \(formatter.string(from: activeSegment.startDate)) -> \(formatter.string(from: activeSegment.endDate))")
            Log.info("Segment Range: \(activeSegment.range)")
        }
        
        return (activeIndex, activeSegment)
    }

    private static func segment(forIndex index: Int, withStartDate startDate: Date, points: [LayerPoint]) -> LayerSegment {
        let nextIndex = (index + 1) % points.count

        let endDate = points[nextIndex].time.calcNextDate(after: startDate)!
        let segmentRange = SegmentRange(origin: points[index].brightness, end: points[nextIndex].brightness)
        return LayerSegment(startDate: startDate, endDate: endDate, range: segmentRange)
    }
}

struct LayerSegment: ChannelSegment {
    var range: SegmentRange
    var startDate: Date
    var endDate: Date

    var startBrightness: Double {
        return range.origin
    }
    
    var endBrightness: Double {
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

    func lightLevel(forDate now: Date) -> Double {
        let timeSpent = max(0.0, now.timeIntervalSince(self.startDate))
        let factor = min(1.0, timeSpent / self.timeDelta)

        return self.range.bound(self.range.origin + (factor * self.range.delta))
    }
}

struct SegmentRange: CustomStringConvertible {
    var origin: Double
    var end: Double

    var delta: Double {
        return self.end - self.origin
    }

    init(origin: Double, end: Double) {
        self.origin = origin
        self.end = end
    }

    func bound(_ value: Double) -> Double {
        let highBound = max(self.origin, self.end)
        let lowBound = min(self.origin, self.end)
        return max(lowBound, min(highBound, value))
    }

    var description: String {
        return "(\(self.origin), ∆\(self.delta))"
    }
}
