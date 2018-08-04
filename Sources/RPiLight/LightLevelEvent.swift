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

import Dispatch
import Foundation
import Logging
import PWM

typealias ChannelValues = [String: ChannelValue]
typealias ChannelLightRanges = [String: LightRange]

struct LightRange {
    var origin: Double
    var delta: Double

    var end: Double {
        return self.origin + self.delta
    }

    init(origin: Double, delta: Double) {
        self.origin = origin
        self.delta = delta
    }

    init(origin: Double, end: Double) {
        self.init(origin: origin, delta: end - origin)
    }
}

extension Event {
    func lightRangesToEvent(event: Event) -> ChannelLightRanges {
        let eventLookup = event.channelValues.reduce(ChannelValues()) { (dict, value) -> ChannelValues in
            var dict = dict
            dict[value.token] = value
            return dict
        }

        var lightRanges: ChannelLightRanges = [:]
        for channelValue in self.channelValues {
            let token = channelValue.token
            guard let eventChannelValue = eventLookup[token] else { continue }
            lightRanges[token] = LightRange(origin: channelValue.brightness, end: eventChannelValue.brightness)
        }

        return lightRanges
    }
}

class LightLevelChangeEvent: LightEvent {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss Z"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    let time: DateComponents
    let endTime: DateComponents
    let behavior: LightLevelChangeBehavior

    static func createFromSchedule(schedule: [Event]) -> [LightEvent] {
        var lightEvents: [LightEvent] = []
        for (index, event) in schedule.enumerated() {
            let nextIndex = (index + 1) % schedule.count
            let nextEvent = schedule[nextIndex]
            let lightRanges = event.lightRangesToEvent(event: nextEvent)
            let lightEvent = LightLevelChangeEvent(startTime: event.time,
                                                   endTime: nextEvent.time,
                                                   lightRanges: lightRanges)
            lightEvents.append(lightEvent)
        }
        return lightEvents
    }

    init(startTime: DateComponents, endTime: DateComponents, lightRanges: ChannelLightRanges) {
        self.time = startTime
        self.endTime = endTime
        self.behavior = LightLevelChangeBehavior(lightRanges: lightRanges)
    }

    func onEvent(now: Date, controller: LightController) {
        self.behavior.reset()

        let behaviorStart = self.time.calcNextDate(after: now, direction: .backward)
        let behaviorEnd = self.endTime.calcNextDate(after: now, direction: .forward)

        Log.info("LightLevelChangedEvent: { \(LightLevelChangeEvent.dateFormatter.string(from: behaviorStart)) -> \(LightLevelChangeEvent.dateFormatter.string(from: behaviorEnd)) }")
        controller.setCurrentBehavior(behavior: self.behavior, startDate: behaviorStart, endDate: behaviorEnd)
    }

}

class LightLevelChangeBehavior: LightBehavior {
    var startDate: Date
    var endDate: Date

    private let lightRanges: ChannelLightRanges

    init(lightRanges: ChannelLightRanges) {
        self.lightRanges = lightRanges
        self.startDate = Date.distantPast
        self.endDate = Date.distantPast
    }

    func complete() {
        // TODO
    }

    func join() {
        // TODO
    }

    func reset() {
        self.startDate = Date.distantPast
        self.endDate = Date.distantPast
    }

    func calcUpdateInterval(withChannels channels: [String: Channel]) -> Double {
        let timeDelta = self.endDate.timeIntervalSince(self.startDate)
        let brightnessDelta = self.lightRanges.map({ return abs($1.delta) }).max()!

        if brightnessDelta == 0.0 {
            return timeDelta * 1000.0
        }
        
        let targetInterval = timeDelta * 1000.0 / (brightnessDelta * 4096)

        let brightnessMin = channels.map({ return $1.brightness }).min()!
        let curveConst = 0.4
        let brightnessFactor = ((1.0 + curveConst) * brightnessMin) / (curveConst + brightnessMin)

        let minInterval = 10.0 // Milliseconds
        let finalInterval = minInterval + (brightnessFactor * (targetInterval - minInterval))
        return finalInterval
    }

    func getLightLevelsForDate(now: Date, channels: [String: Channel]) -> ChannelOutputs {
        let timeSpent = now.timeIntervalSince(self.startDate)
        let factor = min(timeSpent / self.timeDelta, 1.0)

        var channelOutputs: ChannelOutputs = [:]
        for (token, lightRange) in self.lightRanges {
            let brightness = min(lightRange.origin + (factor * lightRange.delta), lightRange.end)
            channelOutputs[token] = brightness
        }

        return channelOutputs
    }
}
