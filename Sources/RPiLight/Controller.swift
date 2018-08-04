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

    var shouldSleep: Bool { get }
    
    func enter()
    func leave()
    func wait()

    func reset()

    func calcUpdateInterval(for now: Date?, withChannels channels: [String: Channel]) -> Double

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
        let NSEC_IN_SEC: UInt64 = 1_000_000_000
        let interval = date.timeIntervalSince1970
        let spec = timespec(tv_sec: Int(interval), tv_nsec: Int(UInt64(interval * Double(NSEC_IN_SEC)) % NSEC_IN_SEC))
        self.init(timespec: spec)
    }
}

class LightController {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss Z"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private let channels: [String: Channel]

    private let queue: DispatchQueue
    private let eventTimer: DispatchSourceTimer
    private let behaviorTimer: DispatchSourceTimer
    private var isBehaviorSuspended: Bool
    private var isBehaviorOneShot: Bool

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
        self.isBehaviorOneShot = false

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
        behavior.enter()
        
        self.queue.async {
            Log.info("Starting New Behavior")
            var localBehavior = behavior
            localBehavior.reset()
            localBehavior.prepareForRunning(startDate: startDate, endDate: endDate)
            self.currentBehavior?.leave()
            self.currentBehavior = localBehavior

            self.scheduleNextBehaviorUpdate(withBehavior: localBehavior)
        }
    }

    func clearCurrentBehavior() {
        self.queue.async {
            Log.info("Ending Current Behavior")
            self.currentBehavior?.leave()
            self.currentBehavior = nil

            self.behaviorTimer.suspend()
            self.isBehaviorSuspended = true
        }
    }

    private func calculateRestart(withBehavior behavior: LightBehavior, now: Date) -> (Date, TimeInterval?) {
        if behavior.shouldSleep {
            return (behavior.endDate, nil)
        } else if now < behavior.startDate {
            return (behavior.startDate, nil)
        } else {
            return (now, behavior.calcUpdateInterval(for: now, withChannels: self.channels))
        }
    }
    
    private func scheduleNextBehaviorUpdate(withBehavior behavior: LightBehavior, now: Date = Date()) {
        if !self.isBehaviorSuspended {
            self.behaviorTimer.suspend()
        }
        
        let (restartDate, updateIntervalMaybe) = self.calculateRestart(withBehavior: behavior, now: now)
        if let updateInterval = updateIntervalMaybe {
            let updateIntervalMs = Int(updateInterval * 1000.0)
            self.behaviorTimer.scheduleRepeating(wallDeadline: DispatchWallTime(date: restartDate), interval: .milliseconds(updateIntervalMs))
            self.isBehaviorOneShot = false
            Log.debug("Scheduling Behavior: \(Log.dateFormatter.string(from: restartDate)) : \(updateIntervalMs) ms")
        } else {
            self.behaviorTimer.scheduleOneshot(wallDeadline: DispatchWallTime(date: restartDate))
            self.isBehaviorOneShot = true
            Log.debug("Scheduling Behavior: \(Log.dateFormatter.string(from: restartDate))")
        }
        
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
        let nextDate = nextEvent.time.calcNextDate(after: now)!

        Log.info("Scheduling Next Event @ \(LightController.dateFormatter.string(from: nextDate))")
        self.eventTimer.scheduleOneshot(wallDeadline: DispatchWallTime(date: nextDate), leeway: .seconds(0))
    }

    private func handleBehavior() {
        let now = Date()
        if let currentBehavior = self.currentBehavior, currentBehavior.startDate <= now {
            let lightLevels = currentBehavior.getLightLevelsForDate(now: now, channels: self.channels)
            for (token, brightness) in lightLevels {
                guard var channel = self.channels[token] else { continue }

                channel.brightness = brightness
            }

            
            if currentBehavior.endDate <= now {
                self.clearCurrentBehavior()
            } else if self.isBehaviorOneShot {
                self.scheduleNextBehaviorUpdate(withBehavior: currentBehavior, now: now)
            }
        }
    }

    private func calcPreviousEventIndex(now: Date) -> Int {
        let (maxIndex, _) = self.schedule.map({ $0.time.calcNextDate(after: now, direction: .backward)! })
            .enumerated()
            .max(by: { $0.element < $1.element })!
        return maxIndex
    }
}
