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
import PWM

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

protocol LightEvent {
    var time: DateComponents { get }

    func onEvent(now: Date, controller: LightController)
}

typealias ChannelOutputs = [String: Double]

protocol LightBehavior {
    var startDate: Date { get set }
    var endDate: Date { get set }

    func complete()
    func join()

    func reset()

    func calcUpdateInterval(withChannels channels: [String: Channel]) -> DispatchTimeInterval

    func getLightLevelsForDate(now: Date, channels: [String: Channel]) -> ChannelOutputs
}

extension LightBehavior {
    var timeDelta: TimeInterval {
        return self.endDate.timeIntervalSince(self.startDate)
    }

    mutating func prepareForRunning(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

extension DispatchWallTime {
    init(date: Date) {
        let spec = timespec(tv_sec: Int(date.timeIntervalSince1970), tv_nsec: 0)
        self.init(timespec: spec)
    }
}

class LightController {
    private let channels: [String: Channel]

    private let queue: DispatchQueue
    private let eventTimer: DispatchSourceTimer
    private let behaviorTimer: DispatchSourceTimer
    private var isBehaviorSuspended: Bool

    private var schedule: [LightEvent]
    private var scheduleIndex: Int
    private var currentBehavior: LightBehavior?
    private var lastBehaviorRefresh: Date?

    init(channels: [Channel]) {
        // Convert the array into a lookup
        self.channels = channels.reduce([String: Channel]()) { (dict, channel) -> [String: Channel] in
            var dict = dict
            dict[channel.token] = channel
            return dict
        }

        self.queue = DispatchQueue(label: "rpilight.controller",
                                   qos: .userInitiated,
                                   attributes: [],
                                   autoreleaseFrequency: .inherit,
                                   target: nil)
        self.schedule = []
        self.scheduleIndex = -1
        self.currentBehavior = nil

        self.eventTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        self.eventTimer.resume()
        self.behaviorTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        self.isBehaviorSuspended = true

        self.eventTimer.setEventHandler {
            [weak self] in
            self?.handleNextEvent()
        }

        self.behaviorTimer.setEventHandler {
            [weak self] in
            self?.handleBehavior()
        }
    }

    func applySchedule(schedule: [Event]) {
        self.queue.async {
            self.schedule = LightLevelChangeEvent.createFromSchedule(schedule: schedule)

            // Figure out which event
            self.scheduleIndex = self.calcPreviousEventIndex(now: Date())
            self.handleNextEvent()
        }
    }

    func setCurrentBehavior(behavior: LightBehavior, startDate: Date, endDate: Date) {
        self.queue.async {
            var localBehavior = behavior
            localBehavior.reset()
            localBehavior.prepareForRunning(startDate: startDate, endDate: endDate)
            self.currentBehavior = localBehavior

            self.rescheduleBehaviorHandler(withBehavior: localBehavior)
        }
    }

    func clearCurrentBehavior() {
        self.queue.async {
            self.currentBehavior?.complete()
            self.currentBehavior = nil

            self.behaviorTimer.suspend()
            self.isBehaviorSuspended = true
        }
    }

    private func rescheduleBehaviorHandler(withBehavior behavior: LightBehavior) {
        if !self.isBehaviorSuspended {
            self.behaviorTimer.suspend()
        }

        let startDate = behavior.startDate
        let updateInterval = behavior.calcUpdateInterval(withChannels: self.channels)
        self.behaviorTimer.scheduleRepeating(wallDeadline: DispatchWallTime(date: startDate),
                                             interval: updateInterval,
                                             leeway: .milliseconds(1))
        self.behaviorTimer.resume()
        self.isBehaviorSuspended = false

        self.lastBehaviorRefresh = Date()
    }

    private func handleNextEvent() {
        let now = Date()
        let event = self.schedule[self.scheduleIndex]

        event.onEvent(now: now, controller: self)

        // Move to the next event
        self.scheduleIndex = (self.scheduleIndex + 1) % self.schedule.count
        let nextEvent = self.schedule[self.scheduleIndex]
        let nextDate = nextEvent.time.calcNextDate(after: now)

        print("Scheduling Next Event @ \(nextDate)")
        self.eventTimer.scheduleOneshot(wallDeadline: DispatchWallTime(date: nextDate), leeway: .seconds(0))
    }

    private func handleBehavior() {
        if let currentBehavior = self.currentBehavior {
            let now = Date()

            let lightLevels = currentBehavior.getLightLevelsForDate(now: now, channels: self.channels)
            for (token, brightness) in lightLevels {
                guard var channel = self.channels[token] else { continue }

                channel.brightness = brightness
            }

            // Update our interval about once a second
            if let lastBehaviorRefresh = self.lastBehaviorRefresh, now.timeIntervalSince(lastBehaviorRefresh) > 1.0 {
                self.rescheduleBehaviorHandler(withBehavior: currentBehavior)
            }

            if currentBehavior.endDate <= now {
                self.clearCurrentBehavior()
            }
        }
    }

    private func calcPreviousEventIndex(now: Date) -> Int {
        let (maxIndex, _) = self.schedule.map({ $0.time.calcNextDate(after: now, direction: .backward) })
            .enumerated()
            .max(by: { $0.element < $1.element })!
        return maxIndex
    }
}
